# Question

Solve this question on: `terminal`

The `starfleet` namespace is running three Deployments, and each has a resource problem. Fix all three by changing only their resource settings. Do not change the images, commands or replica counts, and do not remove the resource settings to get past a problem.

1. The `shuttle` Deployment keeps restarting. Its process needs about 100 MiB of memory at its peak. Find out why the container ends, then give it a memory limit of at least `192Mi` and at most `512Mi`, with a memory request that is not above the limit.

2. The `scout` Deployment must run with the `Guaranteed` quality of service class. Check which containers stop it from being `Guaranteed`. Remember the init container and the sidecar. Every container needs CPU and memory limits, with requests equal to the limits. Keep the sidecar `metrics-agent` in the Pod.

3. The `probe` Deployment has a Pod that stays `Pending`. Find the event that explains it and correct the CPU values. The request must be written in millicores and stay below one core, and the limit must not be below the request.

When you finish, all three Deployments have Ready Pods, and no Pod in `starfleet` is `BestEffort`.

`kubectl` already points at the cluster as the cluster administrator.
