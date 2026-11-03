# Question

Solve this question on: `terminal`

This is the capstone for resource requirements: one integrated task, no step-by-step guidance.

The `starfleet` namespace has a ResourceQuota `starfleet-quota` and three Deployments with resource problems. Fix them without raising or deleting the quota and without changing images, commands or replica counts.

1. The `bridge` Deployment keeps restarting. Its process needs about 100 MiB of memory at its peak. Give it a memory limit between `192Mi` and `512Mi`, with a memory request not above the limit.

2. The `scout` Deployment has no Pods. Find why the API server refuses them. Change the resources so that the Pods are admitted, Ready and in the `Guaranteed` quality of service class. Keep the `log-shipper` sidecar in the Pod. Every container, including the init container, needs CPU and memory limits with requests equal to them.

3. The `shuttle` Deployment has no resources, and the quota refuses its Pod. Do not write resources into the `shuttle` Deployment. Create a LimitRange named `starfleet-defaults` in `starfleet` with one rule of type `Container`: default limits CPU `100m` and memory `64Mi`, default requests CPU `50m` and memory `32Mi`, and maximums CPU `500m` and memory `512Mi`. Then make `shuttle` run with one Ready Pod.

When you finish, all three Deployments have Ready Pods, no Pod is `BestEffort`, and the namespace is inside the quota.

`kubectl` already points at the cluster as the cluster administrator.
