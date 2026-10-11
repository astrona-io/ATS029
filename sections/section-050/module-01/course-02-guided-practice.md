---
draft: true
exam_objectives:
- Define resource requirements
---
# Declare Resources For Every Ordinary Container

A multi-container Pod needs deliberate resource settings for each container. You will declare two distinct request and limit sets, inspect the accepted specification and identify placement evidence. The exercise establishes resource input and scheduling behavior without claiming that observed usage must equal the declared numbers.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-050/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-050-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-050-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save a Pod whose main and supporting containers both have explicit resource settings.

Save this as `pod-resource-pair.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pair
  namespace: starfleet
spec:
  containers:
  - name: main
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 50m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 64Mi
  - name: support
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 20m
        memory: 16Mi
      limits:
        cpu: 50m
        memory: 32Mi
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f pod-resource-pair.yaml
kubectl -n starfleet wait --for=condition=Ready pod/resource-pair --timeout=120s
```

The ordinary container CPU requests total 70 millicores and memory requests total 48 MiB before other scheduling adjustments. Init containers and Pod overhead would add their own rules in a different specification.

Inspect each container setting and the node chosen by scheduling.

```sh
kubectl -n starfleet get pod resource-pair -o jsonpath='{range .spec.containers[*]}{.name}{" "}{.resources}{"\n"}{end}'
kubectl -n starfleet describe pod resource-pair
```

CPU requests influence allocation for placement, while CPU limits constrain selected runtime use. Memory limits can lead to termination when exceeded. These are not interchangeable measurements.

Read process and node evidence without confusing it with configured capacity.

```sh
kubectl -n starfleet exec resource-pair -c main -- ps
kubectl -n starfleet get pod resource-pair -o wide
kubectl get nodes
```

A sleeping process may use far less than its request. If placement fails, inspect the accepted input and events rather than lowering every field without understanding which constraint was exceeded.

Resource design covers every container that contributes to the workload. LimitRange defaults and quotas can alter or reject submitted input, so inspect the accepted specification as well as the file. This keeps the scheduling and enforcement claims tied to actual resource contracts.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
