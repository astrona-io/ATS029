---
draft: true
exam_objectives:
- Define resource requirements
---
# Declare Resources For Every Container

Give both ordinary containers explicit requests and limits without losing application availability. Use the isolated `starfleet` environment to verify the result.

## Objective

Give both ordinary containers explicit requests and limits without losing application availability.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-050-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-050-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Keep two probe replicas and add ordinary container `observer` using BusyBox 1.37.0 with a sleeping process. Declare probe requests of 20m CPU and 32Mi memory with limits of 100m and 128Mi. Declare observer requests of 10m and 16Mi with limits of 50m and 64Mi. Both containers must be ready in both Pods. Preserve the original Service response.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
