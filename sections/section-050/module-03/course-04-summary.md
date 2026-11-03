# Summary

A namespace can shape the resource settings of every Pod in it. A LimitRange adds default requests and limits to containers that set none, and it rejects containers whose values are below a minimum or above a maximum. It acts when the API server admits the Pod, so it never changes Pods that already run. A ResourceQuota caps the total that the namespace may use: the sum of requests, the sum of limits, the number of Pods and other objects. When a quota tracks a resource, every new Pod must state that resource, and a LimitRange default is the usual way to satisfy this.

The place where a failure shows depends on the component that stops the Pod. A direct Pod creation that breaks a quota or a LimitRange maximum fails at once with a `Forbidden` error. A Deployment that breaks the same rule is accepted, and its ReplicaSet records `FailedCreate` events. A Pod that no node can fit stays Pending with a `FailedScheduling` event. A container that goes over its memory limit is killed and shows `OOMKilled`, and a Pod that goes over its ephemeral storage limit is evicted by the kubelet.

Ephemeral storage is the temporary disk space of a Pod: the writable layer of its containers, logs and `emptyDir` volumes. It takes the same request and limit fields as memory, and the scheduler compares the requests with the node's allocatable ephemeral storage. Extended resources are custom countable resources that an administrator adds to a node status. They use whole numbers, cannot be overcommitted, and a Pod that asks for more than any node offers stays Pending. Pod-level resources set one budget for the whole Pod in `spec.resources`, which takes precedence over container values for CPU and memory.

Right-sizing starts from evidence. The symptom tells you where to look: Pod events for scheduling, ReplicaSet events for admission, the last container state for memory kills, and Pod status for evictions. The fix is a change of the resource numbers, made with `kubectl set resources` or an edit of the Deployment, followed by a rollout check. Requests should match what the workload normally needs, the memory limit should sit above its peak, and removing the settings to make a symptom disappear only hides the problem.

Key facts to remember:

- LimitRange defaults and limits apply at admission and never change running Pods.
- ResourceQuota rejects what would push the namespace total over its hard limit.
- Deployments hide quota rejections in ReplicaSet events.
- Ephemeral storage overuse leads to eviction, not to an OOM kill.
- Extended resources have integer quantities and requests must equal limits.

<!-- astrona:playground:destroy -->
