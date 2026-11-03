# Question

Solve this question on: `terminal`

The `starfleet` team runs the `Hangar` API from the group `fleet.astrona.io`. The platform team registered the CustomResourceDefinition `hangars.fleet.astrona.io` in a hurry, and the operator `hangar-operator` in the namespace `fleet-system` cannot keep the `Hangar` named `scout-bay` working. A second `Hangar`, `old-bay`, was deleted days ago and is still listed in `starfleet`. `kubectl` already points at the cluster as the cluster administrator.

1. Repair the CustomResourceDefinition `hangars.fleet.astrona.io` in place. Do not delete it. For the version `v1`:
   - Enable the status subresource.
   - Declare the fields of `status` that the operator writes: `observedGeneration` (integer), `readyReplicas` (integer) and `conditions` (a list of objects with the string fields `type`, `status`, `reason` and `message`).
   - Limit `spec.replicas` to the range 1 to 5.
   - Add the printer columns `Replicas` (from `spec.replicas`) and `Ready` (the `status` of the condition with the type `Ready`).

2. Find out why the operator cannot create the workload of `scout-bay` and fix the cause. The operator uses the service account `hangar-operator` and the `ClusterRole` of the same name. Give it only the permission it is missing. It must not receive `cluster-admin`, `admin` or `edit`, and no wildcard in a rule.

3. `scout-bay` must reach the condition `Ready` with the status `True`, and its status must describe its current generation. The operator must create the Deployment `hangar-scout-bay` with two available replicas, owned by `scout-bay`. Do not create the Deployment by hand and do not delete and create `scout-bay` again.

4. Remove `old-bay` so that it is no longer listed.

`kubectl get hangars -n starfleet` must show the columns `REPLICAS` and `READY`. The operator Deployment must keep running with its own service account.
