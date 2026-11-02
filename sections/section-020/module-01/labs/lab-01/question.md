---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Grant Namespace Pod Read Access

The `starfleet` application needs this task completed in its isolated lab environment.

## Objective

Grant a ServiceAccount only Pod read access in the required namespace and verify denied operations.

## Starting state

The `starfleet` and `outpost` namespaces and `starfleet/shuttle` ServiceAccount exist. A ServiceAccount identifies a workload when it calls the Kubernetes application programming interface (API). It has no application-specific Pod read grant.

Use this lab's private kubeconfig. A kubeconfig contains the cluster address and credentials used by kubectl, the Kubernetes command-line tool. The lab has a separate kind cluster from the module playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-020-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-020-01-01" || exit 1
```

Keep this connection selected for every command below.

## Required result

Create Role `pod-reader` and RoleBinding `shuttle-pod-reader` in `starfleet`. Grant ServiceAccount `shuttle` in `starfleet` exactly `get`, `list` and `watch` on core Pods. The binding must reference that Role and only that ServiceAccount. Do not add a ClusterRoleBinding or any other grant. Pod creation and deletion, Secret reads, Pod reads in `outpost` and node reads must remain denied.

## Verify the result

Inspect the required fields and observe the actual result. The grader checks both the resource contract and effective allowed and denied permissions. Wait for controller convergence before submitting.
