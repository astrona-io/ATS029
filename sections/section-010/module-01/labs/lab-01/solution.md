---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Reconcile A Custom Resource Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-010-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-010-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl api-resources --api-group=training.astrona.io
kubectl explain probesetting.spec --api-version=training.astrona.io/v1
```

A CustomResourceDefinition adds an API type and validation schema. A controller supplies the behavior for that type. The custom resource expresses desired configuration, and the provided controller reconciles an output ConfigMap. Verify the status and the output rather than assuming API acceptance means reconciliation completed.


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

Apply the required change:

```sh
kubectl apply -f probesetting-greeting.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet wait --for=jsonpath='{.status.ready}'=true probesetting/greeting --timeout=120s
```

Create ProbeSetting `greeting` in `starfleet` using `training.astrona.io/v1`, with `spec.message: configured`. The supplied controller must mark it ready and produce ConfigMap `settings-greeting` with `data.message: configured`. Keep the controller running. Do not manually create the output ConfigMap instead of the custom resource.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-010-01-01`.

## Common pitfalls

> [!WARNING]
> Installing an API type does not supply controller behavior. Preserve the supplied controller and create the custom resource. Manually creating its output bypasses reconciliation.
