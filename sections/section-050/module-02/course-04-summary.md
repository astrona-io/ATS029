# Summary

Kubernetes uses two resource settings for different jobs. The request is the amount the container needs, and the scheduler reads it to choose a node with enough unreserved capacity. The limit is the most the container may use, and the kubelet hands it to the container runtime, which makes the Linux kernel enforce it with control groups. The scheduler never uses a limit, and the kernel never uses a request as a ceiling.

CPU and memory fail in different ways. A container that wants more CPU than its limit is throttled: the kernel stops it for the rest of the scheduling period, the Pod stays Running, and only the kernel counters show it. A container that uses more memory than its limit is killed by the kernel, the kubelet records `OOMKilled` and exit code 137, and the restart policy brings it back, often into `CrashLoopBackOff`. Quantities need care: `m` means one thousandth, so `cpu: 500m` is half a core, while `memory: 400m` is a fraction of a byte. Use `Mi` and `Gi` for memory.

The quality of service class comes from the settings and is stored in `status.qosClass`. A Pod is Guaranteed when every container, including init containers, has CPU and memory limits and requests equal to them. It is BestEffort when nothing is set, and Burstable in every other case. Under memory pressure the kubelet evicts BestEffort Pods first and Guaranteed Pods last. A node adds up the requests of its Pods and compares the total with its allocatable amount, which is its capacity minus system reservations. A Pod whose requests do not fit stays Pending with a `FailedScheduling` event that names the short resource.

Init containers and sidecars follow a calculation. A regular init container runs alone, so its need is its own request plus the sidecars declared before it. A sidecar, which is an init container with `restartPolicy: Always`, keeps running beside the application containers. The effective Pod request is the larger of the highest startup need and the sum of all sidecars and application containers, calculated separately for CPU and memory.

Key facts to remember:

- Requests are for scheduling. Limits are enforced by the kernel.
- CPU over the limit means throttling. Memory over the limit means `OOMKilled` and exit code 137.
- Guaranteed needs equal requests and limits on every container for both resources.
- `kubectl describe node` shows requests as a percentage of allocatable.
- The effective request is the maximum of the startup need and the running sum.

<!-- astrona:playground:destroy -->
