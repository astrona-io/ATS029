---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Summary

A ResourceQuota sets a hard ceiling on what one namespace may use. The ResourceQuota admission plugin in the API server enforces it when an object is created or changed, and the resource quota controller in `kube-controller-manager` keeps `status.used` up to date. The quota compares declared values, not measured use, so a container that uses little CPU still counts its full request.

A compute quota limits `requests.cpu`, `requests.memory`, `limits.cpu` and `limits.memory`. When a quota controls a resource, every new pod must declare that resource, or the API server rejects it with a `must specify` error. A pod that declares values above the remaining budget is rejected with an `exceeded quota` error that shows the requested, used and limited amounts. `kubectl create quota` writes a quota in one command, and `kubectl describe quota` shows used and hard values side by side.

Object count and storage quotas follow the same rules with different keys. `count/<resource>.<group>` and the legacy names such as `pods`, `services` and `configmaps` limit how many objects exist. `requests.storage` and `persistentvolumeclaims` limit volume claims, and the per-class keys limit one StorageClass. A volume claim counts from the moment it is stored, even while it is `Pending`.

A quota scope narrows the pods that a quota counts. `BestEffort` matches pods with no requests or limits and can limit only `pods`. `NotBestEffort`, `Terminating`, `NotTerminating` and `PriorityClass` can limit compute totals as well. A quota with several scopes counts only the pods that match all of them.

Controllers hide quota errors from the command that created the workload. A Deployment is accepted, and its ReplicaSet records `FailedCreate` events when the quota refuses a pod. The message tells you which fix is needed: complete the pod template for `must specify`, or change the quota or the demand for `exceeded quota`. A changed quota never removes running pods, and the controller creates the missing pods by itself after the limit grows. The key facts to remember are these:

- A quota counts declared requests and limits, never measured usage.
- A quota is a ceiling, not reserved capacity.
- Read the ReplicaSet events when a Deployment has fewer pods than it should.
- Existing objects are checked only when they are created or changed again.

<!-- astrona:playground:destroy -->
