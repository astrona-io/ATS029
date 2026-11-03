# Overview: Seccomp, Host Access And Pod Security Admission (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a few workloads and two namespaces that have different Pod Security labels, and then waits. There is no task, no `astrona submit` and no pass or fail. Create pods, break them, run `astrona destroy`, and start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. Pod Security Admission is built in and needs no installation.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | No Pod Security labels, so every pod is admitted. `scout` runs `podinfo` and `shuttle` runs `busybox`. Neither has a `securityContext` |
| `outpost` | Labelled `pod-security.kubernetes.io/enforce: baseline` and `pod-security.kubernetes.io/warn: restricted`. `drifter` runs `busybox` |

## Helpers

Paste these once in each new terminal. `seccomp_mode` prints the seccomp line of a pod's main process (0 is no filter, 2 is a filter). `psa_test` runs a server-side dry run of an `enforce` level on a namespace and prints the pods that would break it. `failed_creates` lists the `FailedCreate` events of a namespace.

```sh
seccomp_mode() {
  kubectl -n "$1" exec "$2" -- grep '^Seccomp:' /proc/1/status
}
psa_test() {
  kubectl label --dry-run=server --overwrite namespace "$1" "pod-security.kubernetes.io/enforce=$2"
}
failed_creates() {
  kubectl -n "$1" get events --field-selector reason=FailedCreate
}
```

Use them like this: `seccomp_mode starfleet deploy/shuttle`, `psa_test outpost restricted`, `failed_creates outpost`.

## Practice tasks

- Run `seccomp_mode` on `shuttle`, then create a pod with `seccompProfile.type: RuntimeDefault` and run it again. Predict the result first.
- Create a pod with `readOnlyRootFilesystem: true`, try `touch /file`, then add an `emptyDir` volume at `/tmp` and try `touch /tmp/file`.
- Create a pod with `hostNetwork: true` in `starfleet`, and compare its pod IP with its host IP. Then try the same pod in `outpost` and read the rejection.
- Mount a `hostPath` directory read-only in a `starfleet` pod and read a file of the node.
- Set the safe sysctl `net.ipv4.ip_local_port_range` in a pod, then an unsafe one such as `kernel.msgmax`, and compare the pod status.
- Enforce `restricted` on `outpost`, create a Deployment with no `securityContext`, and find the rejection in the events of its ReplicaSet.
