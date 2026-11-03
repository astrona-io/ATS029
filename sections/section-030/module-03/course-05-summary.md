---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Summary

A LimitRange is the policy for one container, pod or volume claim in a namespace. The LimitRanger admission plugin in the API server fills in missing requests (`defaultRequest`) and limits (`default`) for containers, then checks the object against `min`, `max` and `maxLimitRequestRatio`. A rejection names the rule, the object type and the allowed value. The plugin acts only when an object is created or changed, so existing pods keep their stored values. A container that sets only a limit gets a request equal to that limit before the plugin runs.

The API server assigns each pod a quality of service (QoS) class when it creates the pod, and the class never changes. A pod is `Guaranteed` when every container has CPU and memory limits and requests equal to them. It is `BestEffort` when no container sets any request or limit. Every other pod is `Burstable`. You read the class from `.status.qosClass`, and you change it by changing the pod template of the workload.

Limits are enforced on the node, and the two resources behave differently. A CPU limit becomes a time quota in each 100 millisecond period, and a container that reaches it is throttled and slowed down, but not stopped. A memory limit is a hard maximum. A container that goes over it is killed by the kernel, and the pod status records `OOMKilled` with exit code 137. A container that dies repeatedly shows `CrashLoopBackOff`, and `lastState.terminated.reason` gives the cause.

Placement and eviction depend on requests and classes. The scheduler adds up the requests of the pods on a node and compares them with allocatable resources, not with current use. A pod that fits no node stays `Pending` with a `FailedScheduling` event such as `Insufficient cpu`, and a larger quota does not help. When a node runs short of memory, the kubelet evicts pods whose use is above their requests first, then lower priority pods, and it evicts `Guaranteed` pods last. The key facts to remember are these:

- A LimitRange changes only objects that are created or changed after it exists.
- The QoS class comes from requests and limits and is fixed at pod creation.
- CPU over the limit means throttling. Memory over the limit means an OOM kill.
- `Pending` with `FailedScheduling` is a node capacity problem, not a quota problem.

<!-- astrona:playground:destroy -->
