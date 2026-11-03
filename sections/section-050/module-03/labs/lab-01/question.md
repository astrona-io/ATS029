# Question

Solve this question on: `terminal`

The `outpost` namespace has a ResourceQuota `outpost-quota` and two Deployments, and neither is healthy. The `drifter` Deployment has no resource settings, and the quota refuses its Pods. The `beacon` Deployment has a CPU limit that uses the whole CPU limit quota. Fix the namespace with a LimitRange and a quota change. Do not delete the quota.

1. Create a LimitRange named `outpost-defaults` in `outpost` with one rule of type `Container`:
   - default limits: CPU `200m`, memory `128Mi`, ephemeral storage `200Mi`
   - default requests: CPU `100m`, memory `64Mi`, ephemeral storage `50Mi`
   - maximums: CPU `500m`, memory `256Mi`

2. Make `drifter` run with 2 ready Pods. Do not write resources into the `drifter` Deployment. Its Pods must get their values from the LimitRange.

3. The `beacon` Deployment must keep running, but its limits must fit inside the new maximums. Change its resources so that the CPU limit is at most `500m` and the memory limit is at most `256Mi`. Keep a request for CPU and memory that is not above the limit.

4. Extend `outpost-quota` so that it also caps ephemeral storage: `requests.ephemeral-storage` of `1Gi` and `limits.ephemeral-storage` of `2Gi`. Keep all its existing values. Every Pod in `outpost` must then state ephemeral storage requests and limits.

`kubectl` already points at the cluster as the cluster administrator.
