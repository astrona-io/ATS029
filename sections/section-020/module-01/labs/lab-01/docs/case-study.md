---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Starting Environment

The `starfleet` and `outpost` namespaces and `starfleet/shuttle` ServiceAccount exist. A ServiceAccount identifies a workload when it calls the Kubernetes application programming interface (API). It has no application-specific Pod read grant.

Create Role `pod-reader` and RoleBinding `shuttle-pod-reader` in `starfleet`. Grant ServiceAccount `shuttle` in `starfleet` exactly `get`, `list` and `watch` on core Pods. The binding must reference that Role and only that ServiceAccount. Do not add a ClusterRoleBinding or any other grant. Pod creation and deletion, Secret reads, Pod reads in `outpost` and node reads must remain denied.
