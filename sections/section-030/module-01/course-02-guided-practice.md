---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Observe Quota Rejection And Resource Accounting

Quota limits namespace consumption according to selected resource dimensions. You will add a small request budget to the isolated namespace and attempt a Pod whose CPU request exceeds it. This exposes admission accounting rather than pretending that quota is a live CPU-usage meter.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-030/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-030-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-030-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save and apply the quota, then inspect its used and hard values.

Save this as `resourcequota-practice.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: practice-budget
  namespace: starfleet
spec:
  hard:
    requests.cpu: 100m
    requests.memory: 256Mi
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f resourcequota-practice.yaml
kubectl -n starfleet describe resourcequota practice-budget
kubectl -n starfleet get deployment probe -o yaml
```

Existing workload requests contribute to accounting. A running container using little CPU does not erase its declared request from the quota population.

Save an explicitly over-budget Pod and expect admission rejection. It includes memory and CPU settings so the intended failure is not an unexplained missing resource field.

Save this as `pod-over-budget.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: over-budget
  namespace: starfleet
spec:
  containers:
  - name: work
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 200m
        memory: 32Mi
      limits:
        cpu: 200m
        memory: 64Mi
```

Apply or use the saved input, then check the result:

```sh
if kubectl apply -f pod-over-budget.yaml; then printf "Over-budget Pod unexpectedly accepted\n" >&2; exit 1; fi
kubectl -n starfleet get pod over-budget --ignore-not-found
kubectl -n starfleet describe resourcequota practice-budget
```

Read the actual rejection and confirm that no accepted Pod exists. This differs from a Pod that the API accepts but the scheduler later leaves Pending.

Remove only the exercise quota after observing the contract.

```sh
kubectl -n starfleet delete resourcequota practice-budget
kubectl -n starfleet get pods
```

Removing the quota stops this accounting restriction. It does not make node capacity unlimited or eliminate other admission and scheduling rules.

Requests, runtime enforcement and namespace budgets operate at different boundaries. Diagnose whether a request was rejected before persistence, remained Pending after acceptance or failed at runtime. The same visible absence of a ready process can arise through all three paths.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
