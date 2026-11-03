# Question

Solve this question on: `terminal`

The `drifter` Deployment in the `outpost` namespace runs containers with no resource values, and a recent mistake scaled a workload there to 40 replicas. The `starfleet` namespace is not part of the rule change. `kubectl` already points at the cluster as the cluster administrator.

1. Create the `LimitRange` `container-limits` in `outpost`. A container that sets no resources must receive the request `cpu: 50m` and `memory: 32Mi` and the limit `cpu: 200m` and `memory: 64Mi`.

2. Create the `ValidatingAdmissionPolicy` `replica-limit`. It must reject a Deployment with more than 3 replicas, when the Deployment is created and when it is updated. The message must tell the user the limit.

3. Create the `ValidatingAdmissionPolicyBinding` `replica-limit-outpost`. It must enforce the policy by rejecting requests, and it must apply only to the namespace `outpost`. A Deployment with 5 replicas in `starfleet` must still be accepted.

Do not delete or change the `drifter` and `scout` Deployments.
