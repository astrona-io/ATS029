# Question

Solve this question on: `terminal`

The `outpost` namespace runs two Deployments. The `drifter` Deployment declares no requests and no limits. The `beacon` Deployment keeps restarting, because the application inside needs more memory than its limit allows. No LimitRange exists in the namespace.

1. Create a LimitRange named `outpost-limits` in `outpost` with one entry of type `Container` and these values: default limit `cpu` 200m and `memory` 256Mi, default request `cpu` 100m and `memory` 128Mi, minimum `cpu` 50m and `memory` 64Mi, maximum `cpu` 500m and `memory` 512Mi, and a `maxLimitRequestRatio` for `cpu` of 4.

2. Make the `drifter` pod receive the defaults from the LimitRange. Do not write requests or limits into the `drifter` Deployment.

3. Find out why `beacon` restarts and fix the Deployment. After the fix, the `beacon` pod must run without restarts and must have the QoS class `Guaranteed`. Keep one replica, and stay inside the LimitRange.

A pod with a memory limit of 1Gi must be rejected in `outpost`. Do not raise the maximum values and do not delete the LimitRange.

`kubectl` already points at the cluster as the cluster administrator.
