---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Use A Workload Identity For An API Request

Run the application with a narrow identity and authenticate a real API request from its container. Use the isolated `starfleet` environment to verify the result.

## Objective

Run the application with a narrow identity and authenticate a real API request from its container.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-070-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-070-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Create ServiceAccount `observer`, Role `observer-reader` granting exactly get and list on core Pods, and RoleBinding `observer-read` for that identity in `starfleet`. Run both probe replicas as that ServiceAccount. A request from the application container using its mounted token and certificate authority must read the namespace Pod list. Secret reads and Pod creation must remain denied.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
