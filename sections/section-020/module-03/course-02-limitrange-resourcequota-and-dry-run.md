---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# LimitRange, ResourceQuota And Server-Side Dry Run

Two built-in admission plugins control how much a team can ask for. `LimitRanger` gives containers default resource values and keeps each container inside a minimum and a maximum. `ResourceQuota` caps the total a namespace can use. Both act on pods at creation time, and both produce errors that confuse people because the error appears on a ReplicaSet and not on the command they ran. This part configures both in the `outpost` namespace, reads their rejections, and uses `--dry-run=server` to preview a decision without storing anything.

## LimitRange sets defaults and bounds for containers

A **LimitRange** is a namespaced object that holds per-object resource rules. The `LimitRanger` plugin reads the LimitRange objects of the pod's namespace on every pod creation. For a container of type `Container`, it uses these fields:

- `defaultRequest` is the request that the plugin writes into a container that has no request for that resource.
- `default` is the limit that the plugin writes into a container that has no limit.
- `min` and `max` are bounds. The plugin rejects a container whose request is below the minimum or whose limit is above the maximum.

Save this as `limitrange-container-limits.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: outpost
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 50m
        memory: 32Mi
      default:
        cpu: 200m
        memory: 64Mi
      max:
        cpu: 500m
        memory: 256Mi
```

Apply it:

```sh
kubectl apply -f limitrange-container-limits.yaml
```

Then check the result:

```sh
kubectl -n outpost describe limitrange container-limits
```

The output lists the type `Container` with the resources, the minimum, the maximum, the default request and the default limit. Creating a LimitRange changes nothing that already exists. The `drifter` pod still has no resources, because the plugin acts only when a pod is created.

## Defaults appear in new pods

The pod template in the `drifter` Deployment has no resources. Restart the Deployment so that the ReplicaSet creates a new pod, and read the resources of the new pod:

```sh
kubectl -n outpost rollout restart deployment drifter
kubectl -n outpost rollout status deployment drifter
kubectl -n outpost get pods -l app=drifter -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

The last command prints a JSON object with the requests `cpu: 50m` and `memory: 32Mi`, and the limits `cpu: 200m` and `memory: 64Mi`. The Deployment template still has no resources. The `LimitRanger` plugin wrote the values into the pod when the ReplicaSet created it. This is a mutation, and it is why a pod can run with limits that you never wrote.

The default limits also matter at run time. A container that uses more memory than its limit is stopped by the kernel and shows `OOMKilled`. A default of `64Mi` is small. Set the resources in your manifests when the application needs more.

## A pod above the maximum is rejected

The same plugin validates. Save this as `pod-too-large.yaml`. It asks for a memory limit above the maximum of `256Mi`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe
  namespace: outpost
spec:
  containers:
    - name: probe
      image: busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      resources:
        limits:
          memory: 1Gi
```

Apply it with a server-side dry run:

```sh
kubectl apply -f pod-too-large.yaml --dry-run=server
```

The command fails with `Forbidden`. The message says that the maximum memory usage per `Container` is `256Mi` and that the limit is `1Gi`. It names the resource, the bound and your value, so you know what to change.

The flag `--dry-run=server` sends the real request to the API server with a marker that tells it not to store the object. The request passes authentication, authorization and every admission step, including mutating ones, and the API server returns the result. With `-o yaml` you see the object as it would be stored, with all defaults. The flag `--dry-run=client` is different. It never contacts admission, so it cannot show a LimitRange or quota rejection. It only checks that the YAML parses.

## ResourceQuota caps the namespace

A **ResourceQuota** is a namespaced object that limits the total resources and object counts in the namespace. The `ResourceQuota` plugin checks every create request against it and rejects the request that would go over a limit. Create a quota that allows two pods in `outpost`:

```sh
kubectl -n outpost create quota outpost-pods --hard=pods=2
kubectl -n outpost describe quota outpost-pods
```

The `describe` command shows a table with `Resource`, `Used` and `Hard`. The `pods` row shows `Used` as the pods that count now, which is one, and `Hard` as two. Scale the `drifter` Deployment to three replicas and look at the result:

```sh
kubectl -n outpost scale deployment drifter --replicas=3
kubectl -n outpost get deployment drifter
kubectl -n outpost get events --field-selector reason=FailedCreate
```

The scale command succeeds, because the Deployment object is valid. The Deployment shows two of three replicas ready. The event list holds a `FailedCreate` event from the ReplicaSet. Its message says that creating the pod is forbidden with `exceeded quota: outpost-pods`, and it shows the requested amount, the used amount and the limit of `pods=2`.

The rejection happened when the ReplicaSet controller tried to create the third pod, not when you ran the `scale` command. This is why a Deployment can look accepted while pods are missing. When replicas are fewer than expected, read the events of the ReplicaSet.

A quota on `requests.cpu` or `limits.memory` adds a rule: every new pod must set that value, or the plugin rejects the pod. A LimitRange with defaults satisfies the rule, because the `LimitRanger` plugin runs first and fills in the values.

## Preview a decision before you apply it

A server-side dry run of a new pod now shows the quota rejection with nothing stored:

```sh
kubectl -n outpost run extra --image=busybox:1.37.0 --dry-run=server
kubectl -n outpost run extra --image=busybox:1.37.0 --dry-run=client
```

The first command fails with `exceeded quota`, because two pods already exist. The second prints `pod/extra created (dry run)`, which is wrong for this cluster: it never asked the API server. A dry run does not consume quota, so you can repeat it freely.

Remove the quota and scale back, so the namespace returns to its first state:

```sh
kubectl -n outpost delete quota outpost-pods
kubectl -n outpost scale deployment drifter --replicas=1
```

You now know that `LimitRanger` fills in and bounds resources, that `ResourceQuota` caps totals, and that a server-side dry run shows both decisions without a side effect. These plugins have fixed rules. The open question is how to write a rule of your own, such as a limit on replicas, without running a webhook server.

## Common pitfalls

> [!WARNING]
> - **Expecting a LimitRange to change running pods.** It acts only on pods created after it exists. Restart the workload to apply it.
> - **Looking for the quota error on the `scale` or `apply` command.** A controller creates the pods, so the error is a `FailedCreate` event on the ReplicaSet.
> - **Trusting `--dry-run=client` for policy checks.** It never reaches admission. Use `--dry-run=server`.
> - **Setting a quota on cpu or memory without defaults.** Pods that set no value are rejected until a LimitRange provides defaults.
> - **Forgetting the default limits are enforced.** A container above its default memory limit is killed with `OOMKilled`.
