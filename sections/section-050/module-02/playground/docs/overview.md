# Overview: Requests, Limits And Quality Of Service (Playground)

This is a playground, not a lab. It starts a fresh cluster with three Deployments and then waits. There is no task, no `astrona submit` and no pass or fail. Change resource settings, break them, run `astrona destroy`, and start over.

## What is in the environment

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. The metrics server is not installed, so `kubectl top` reports that the Metrics API is not available.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` has requests equal to limits (Guaranteed). `probe` has requests below limits (Burstable). `shuttle` has no resources (BestEffort) |

## Helper

Paste this once in each new terminal. It prints the quality of service class of every Pod in a namespace.

```sh
show_qos() {
  kubectl -n "$1" get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
}
```

Use it like this: `show_qos starfleet`.

## Practice tasks

- Predict the class of each Pod, then run `show_qos starfleet`.
- Change the `probe` Deployment so its requests equal its limits for both resources. Check the new class after the rollout.
- Run a Pod with `tail /dev/zero` and a memory limit of `32Mi`. Find the `OOMKilled` reason and the exit code.
- Run a busy loop with a CPU limit of `100m` and read `/sys/fs/cgroup/cpu.stat` twice.
- Create a Pod that requests `1000Gi` of memory. Read the `FailedScheduling` event.
- Create a Pod with an init container and a sidecar, calculate its effective request, and compare it with `kubectl describe node`.
