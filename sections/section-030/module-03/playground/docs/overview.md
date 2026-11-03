# Overview: Defaults, QoS Classes And Runtime Limits (Playground)

This is a playground, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Create LimitRange objects, start pods that misbehave, `astrona destroy`, start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. There is no metrics server, so `kubectl top` does not work. The image `python:3.13-alpine` is preloaded for memory tests.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` (`podinfo`), `probe` (`go-httpbin`) and `shuttle` (`curl`), one replica each, with small CPU and memory requests and a memory limit. The Services `scout` and `probe` |
| `outpost` | The `drifter` client, one replica, with small requests and a memory limit |

No LimitRange and no ResourceQuota exist in either namespace.

## Helpers

Paste these once in each new terminal. `pod_qos` prints the QoS class of every pod in a namespace. `last_termination` prints the reason and exit code of the last termination of the first container of a pod.

```sh
pod_qos() {
  kubectl -n "$1" get pods -o custom-columns='NAME:.metadata.name,QOS:.status.qosClass'
}
last_termination() {
  kubectl -n "$1" get pod "$2" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}{" "}{.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
}
```

Use them like this: `pod_qos starfleet` and `last_termination starfleet memory-hog`.

## Practice tasks

- Write a LimitRange for `outpost` with a default limit, a default request and a maximum. Run `kubectl -n outpost rollout restart deployment/drifter` and read the stored resources of the new pod before you look at the LimitRange.
- Create a pod with only `requests` and no limits, and one with only `limits` and no requests. Predict the stored values and the QoS class, then check with `pod_qos`.
- Add a `Pod` type entry to a LimitRange with a `max` that is smaller than the sum of two containers in a test pod. Read the message.
- Start a pod that allocates more memory than its limit with `python -c`. Find the reason and exit code with `last_termination`.
- Start a pod that requests more memory than the node has and read the `FailedScheduling` event.
