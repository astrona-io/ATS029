---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Create A Custom Resource And Observe Its Controller

This module includes a small real controller for the namespaced ProbeSetting custom resource. The controller copies spec.message into a ConfigMap and reports observed generation in status. You will distinguish the API definition, your desired object and the controller-produced outcome instead of assuming that a CRD performs work by itself.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-010/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-010-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-010-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Discover the custom API and inspect its schema and implementation workload.

```sh
kubectl api-resources --api-group=training.astrona.io
kubectl explain probesetting.spec --api-version=training.astrona.io/v1
kubectl -n starfleet get deployment settings-controller
```

The CRD supplies the schema. The running controller supplies the domain action and uses a limited ServiceAccount. Both are required for the observed outcome.

Save a custom object and wait for the controller to report its completed reconciliation.

Save this as `probesetting-greeting.yaml`:

```yaml
apiVersion: training.astrona.io/v1
kind: ProbeSetting
metadata:
  name: greeting
  namespace: starfleet
spec:
  message: configured
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f probesetting-greeting.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.ready}'=true probesetting/greeting --timeout=60s
kubectl -n starfleet get configmap settings-greeting -o yaml
```

The ConfigMap is a concrete effect of the controller. Creation of the custom resource alone is an earlier API result and would not prove that effect.

Change desired message and observe the corresponding ConfigMap and generation.

```sh
kubectl -n starfleet patch probesetting greeting --type=merge -p '{"spec":{"message":"updated"}}'
kubectl -n starfleet wait --for=jsonpath='{.data.message}'=updated configmap/settings-greeting --timeout=60s
kubectl -n starfleet get probesetting greeting -o yaml
kubectl -n starfleet logs deployment/settings-controller --tail=10
```

The update should appear after a controller cycle. Compare metadata.generation with status.observedGeneration to avoid interpreting a stale ready flag as proof of the latest update.

The controller is intentionally narrow: it manages ConfigMap content, not arbitrary application deployment or infrastructure. Its limitations and deletion behavior are documented for authors. The exercise demonstrates actual repeated implementation while keeping the custom API separate from its operational meaning.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
