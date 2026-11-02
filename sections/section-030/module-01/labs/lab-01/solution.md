---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Declare And Inspect A Namespace Pod Budget Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-030-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-030-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get deployment probe -o yaml
```

A ResourceQuota limits admitted resources within a namespace. The quota controller records usage from existing objects. A hard limit does not reserve capacity for one application, so inspect used capacity before adding work. The task preserves existing workload availability while the quota becomes active.


Save this as `resourcequota-practice-budget.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: practice-budget
  namespace: starfleet
spec:
  hard:
    pods: '5'
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: quota-plan
  namespace: starfleet
data:
  capacity: '5'
```

Apply the required change:

```sh
kubectl apply -f resourcequota-practice-budget.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet exec shuttle -- wget -q -T 3 -O- http://probe/
```

Create ResourceQuota `practice-budget` in `starfleet` with a hard limit of five Pods. Preserve the two healthy probe replicas and shuttle client. Create ConfigMap `quota-plan` with `capacity: "5"`. Quota status must reflect the five-Pod limit and account for at least the three running fixture Pods. Keep usage within the quota. Inspect the measured headroom before proposing another workload.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-030-01-01`.

## Common pitfalls

> [!WARNING]
> The hard limit applies to the whole namespace. Existing Pods consume part of that budget. Wait for usage accounting before calculating headroom; quota does not reserve capacity for one application.
