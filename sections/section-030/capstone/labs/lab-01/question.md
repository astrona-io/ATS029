# Question

Solve this question on: `terminal`

This is the Section 030 capstone: one integrated task about requests, limits and quotas, with no step-by-step guidance.

The `starfleet` namespace is being given a resource budget. It runs two Deployments. The `probe` Deployment has three replicas and declares no requests and no limits. The `bridge` Deployment keeps restarting, because the application inside needs more memory than its limit allows. The namespace has no LimitRange and no ResourceQuota.

1. Create a LimitRange named `starfleet-limits` with one entry of type `Container`: default limit `cpu` 200m and `memory` 256Mi, default request `cpu` 100m and `memory` 128Mi, minimum `cpu` 50m and `memory` 64Mi, maximum `cpu` 500m and `memory` 512Mi.

2. Create a ResourceQuota named `starfleet-budget` with these hard limits: `requests.cpu` 1, `requests.memory` 1Gi, `limits.cpu` 2, `limits.memory` 2Gi and `pods` 6.

3. The three `probe` pods must run under the new rules and carry the default requests and limits from the LimitRange. Do not write requests or limits into the `probe` Deployment.

4. Fix `bridge`. After the fix, its single pod must run without restarts and must have the QoS class `Guaranteed`. It must fit the LimitRange and the quota.

A pod that requests 512Mi of memory must be refused by the quota, and a pod with a 1Gi memory limit must be refused by the LimitRange. Do not delete the quota or the LimitRange, and do not raise any of their values.

`kubectl` already points at the cluster as the cluster administrator.
