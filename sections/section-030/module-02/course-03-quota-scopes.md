---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Quota Scopes

A quota without a scope counts every pod in the namespace. Often that is too coarse. A team may want to allow only a few pods that declare no resources, or only a few short-lived batch pods, while ordinary workloads stay free. A quota scope selects a subset of pods, so one quota counts and limits only the pods that match. This part explains the scopes, which resources each one can limit, and shows two of them working.

## The scopes

A scope is a filter on the pod. Each scope is a fixed condition, and a quota with several scopes counts only the pods that match all of them.

| Scope | Pods that match | Resources the quota may limit |
| --- | --- | --- |
| `BestEffort` | Pods whose quality of service (QoS) class is `BestEffort`: no container sets a request or a limit | `pods` only |
| `NotBestEffort` | Pods that are not `BestEffort` | `pods`, `cpu`, `memory`, `requests.cpu`, `requests.memory`, `limits.cpu`, `limits.memory` |
| `Terminating` | Pods with `spec.activeDeadlineSeconds` set to a value of zero or more | The same list as `NotBestEffort` |
| `NotTerminating` | Pods that do not set `activeDeadlineSeconds` | The same list as `NotBestEffort` |
| `PriorityClass` | Pods that name a PriorityClass that matches a selector | The same list as `NotBestEffort` |

`activeDeadlineSeconds` is a pod field that sets how long the pod may run before the cluster stops it. Jobs commonly set it. A quota scope is written either as a `scopes` list, which holds scope names, or as a `scopeSelector`, which uses `matchExpressions`. The `PriorityClass` scope needs the selector form, because it must compare a PriorityClass name with an operator (`In`, `NotIn`, `Exists` or `DoesNotExist`). The other scopes use the operator `Exists`.

One rule surprises people. A quota whose scopes include `BestEffort` may limit only `pods`. The reason is that a `BestEffort` pod has no requests and no limits, so CPU and memory totals for those pods are always zero.

## Limit pods that declare no resources

Scenario: the `starfleet` namespace should allow at most one pod that has no requests and no limits, because such pods are the first to be evicted when a node runs short of memory.

<!-- astrona:playground:renew -->

Save this as `quota-besteffort-pods.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: besteffort-pods
  namespace: starfleet
spec:
  hard:
    pods: "1"
  scopes:
  - BestEffort
```

Apply it:

```sh
kubectl apply -f quota-besteffort-pods.yaml
```

The three running pods in `starfleet` set requests, so none of them is `BestEffort`, and the quota starts with 0 of 1 pods used. Start two pods that declare nothing:

```sh
kubectl -n starfleet run idle-one --image=curlimages/curl:8.22.0 --command -- sleep 3600
kubectl -n starfleet run idle-two --image=curlimages/curl:8.22.0 --command -- sleep 3600
```

The first pod is admitted and the quota shows 1 of 1 pods. The second command fails with `Forbidden` and a message that starts `exceeded quota: besteffort-pods`. The quota did not look at how much CPU the pods use. It counted the pods that match the scope.

A pod that sets any request or limit does not match the scope, so this quota does not count it. Save this as `pod-idle-requests.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: idle-requests
  namespace: starfleet
spec:
  containers:
  - name: idle
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
```

Apply it:

```sh
kubectl apply -f pod-idle-requests.yaml
kubectl -n starfleet describe quota besteffort-pods
```

The pod is admitted, and the quota still shows 1 of 1. Remove the scoped quota and the test pods before the next exercise:

```sh
kubectl -n starfleet delete pod idle-one idle-requests
kubectl -n starfleet delete quota besteffort-pods
```

## Limit pods that have a deadline

Batch pods differ from services. A Job runs pods that finish, and they usually set `activeDeadlineSeconds` so a stuck pod stops. A team can allow many service pods and only a few batch pods by using the `Terminating` scope. Save this as `quota-batch-pods.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: batch-pods
  namespace: starfleet
spec:
  hard:
    pods: "1"
  scopeSelector:
    matchExpressions:
    - scopeName: Terminating
      operator: Exists
```

Apply it:

```sh
kubectl apply -f quota-batch-pods.yaml
```

Now save a Job that wants two pods at the same time. The deadline is in the pod template, because that is the field the scope reads. Save this as `job-survey.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: survey
  namespace: starfleet
spec:
  completions: 2
  parallelism: 2
  template:
    spec:
      activeDeadlineSeconds: 600
      restartPolicy: Never
      containers:
      - name: survey
        image: curlimages/curl:8.22.0
        command: ["sh", "-c", "sleep 120"]
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
```

Apply it and look at what the Job controller did:

```sh
kubectl apply -f job-survey.yaml
kubectl -n starfleet get pods -l job-name=survey
kubectl -n starfleet describe job survey
```

The Job is accepted, because the quota counts pods and the Job is not a pod. Only one pod exists. In the events at the end of `describe job`, the Job controller records a warning with the reason `FailedCreate`, and its message contains `exceeded quota: batch-pods`. The controller retries with a growing delay. When the first pod finishes, the quota frees one slot, and the controller can create the second pod without any action from you.

Delete the Job and the quota:

```sh
kubectl -n starfleet delete job survey
kubectl -n starfleet delete quota batch-pods
```

You now know the scopes, that `BestEffort` can limit only `pods`, and that a controller reports a quota refusal as an event instead of failing the object it manages. The last part follows that behaviour for Deployments and shows how a changed quota repairs it.

## Common pitfalls

> [!WARNING]
> - **Putting `requests.cpu` in a `BestEffort` quota.** A `BestEffort` quota can limit only `pods`, because those pods declare no CPU or memory. Use `NotBestEffort` for compute totals.
> - **Setting the deadline on the Job only.** A Job's own `spec.activeDeadlineSeconds` is enforced by the Job controller. The `Terminating` scope reads the pod's `spec.activeDeadlineSeconds`, so set it in `spec.template.spec`.
> - **Expecting two scopes to be an OR.** A quota with several scopes counts only pods that match all of them.
> - **Using `scopes` for `PriorityClass`.** The `PriorityClass` scope needs `scopeSelector` with an operator and, for `In` and `NotIn`, a list of values.
