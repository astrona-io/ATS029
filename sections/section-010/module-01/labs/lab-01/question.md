---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Reconcile A Custom Resource

Create a served custom resource and verify its controller-managed output. Use the isolated `starfleet` environment to verify the result.

## Objective

Create a served custom resource and verify its controller-managed output.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-010-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-010-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Create ProbeSetting `greeting` in `starfleet` using `training.astrona.io/v1`, with `spec.message: configured`. The supplied controller must mark it ready and produce ConfigMap `settings-greeting` with `data.message: configured`. Keep the controller running. Do not manually create the output ConfigMap instead of the custom resource.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
