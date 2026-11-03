# Question

Solve this question on: `terminal`

The `starfleet` team asked for a `Hangar` named `scout-bay` with two replicas. The operator `hangar-operator` in the namespace `fleet-system` runs, but `scout-bay` never becomes ready. A second `Hangar`, `old-bay`, was deleted days ago and is still listed in `starfleet`. `kubectl` already points at the cluster as the cluster administrator.

1. Find out why `scout-bay` does not reconcile and fix the cause. The operator uses the service account `hangar-operator` and the `ClusterRole` of the same name. Give the operator only the permission it is missing. It must not receive `cluster-admin`, `admin` or `edit`, and no wildcard in a rule.

2. `scout-bay` must reach the condition `Ready` with the status `True`. The operator must create the Deployment `hangar-scout-bay`, with two available replicas, and the Deployment must be owned by `scout-bay`. Do not create the Deployment by hand and do not delete and create `scout-bay` again.

3. Remove `old-bay` so that it is no longer listed. Do not delete the CRD `hangars.fleet.astrona.io`.

The operator Deployment must keep running with its own service account.
