---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Declare And Inspect A Namespace Pod Budget

Set a namespace Pod quota and inspect the measured capacity already in use. Use the isolated `starfleet` environment to verify the result.

## Objective

Set a namespace Pod quota and inspect the measured capacity already in use.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-030-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-030-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Create ResourceQuota `practice-budget` in `starfleet` with a hard limit of five Pods. Preserve the two healthy probe replicas and shuttle client. Create ConfigMap `quota-plan` with `capacity: "5"`. Quota status must reflect the five-Pod limit and account for at least the three running fixture Pods. Keep usage within the quota. Inspect the measured headroom before proposing another workload.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
