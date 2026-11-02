---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Consume A Mounted ConfigMap

Mount non-secret configuration and verify the application actually reads it. Use the isolated `starfleet` environment to verify the result.

## Objective

Mount non-secret configuration and verify the application actually reads it.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-040-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-040-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Create ConfigMap `probe-settings` with `greeting: mounted`. Mount it as read-only volume `settings` at `/settings` in container `probe`. Keep two healthy replicas and the existing application code. The original client must receive `greeting=mounted` from the application, which reads the mounted file for each request.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
