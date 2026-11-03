# Overview: Namespace Policy, Storage And Right-Sizing (Playground)

This is a playground, not a lab. It starts a fresh cluster with a namespace policy and two broken Deployments, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the numbers, break them, run `astrona destroy`, and start over.

## What is in the environment

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. The metrics server is not installed.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | No policy. `scout` runs. `bridge` has a memory limit of `32Mi` and is killed. `shuttle` requests `cpu: "50"` and stays Pending |
| `outpost` | LimitRange `outpost-defaults` (default request 100m CPU and 64Mi memory, maximum 500m CPU and 256Mi memory) and ResourceQuota `outpost-quota` (6 Pods, 1 CPU of requests). `drifter` runs |

## Helper

Paste this once in each new terminal. It prints the events that explain a creation failure in a namespace.

```sh
failed_creates() {
  kubectl -n "$1" get events --field-selector reason=FailedCreate
}
```

Use it like this: `failed_creates outpost`.

## Practice tasks

- Fix `bridge` and `shuttle` with `kubectl set resources`, and check the rollout.
- Create a Pod in `outpost` with no resources and read the values the LimitRange added.
- Scale `drifter` to 10 replicas and find the quota event that stops it.
- Change the quota so `requests.cpu` is `2` and watch the missing replicas appear.
- Create a Pod with an ephemeral storage limit of `50Mi` that writes 100 MB, and find the `Evicted` status.
- Patch an extended resource into the node status and request it from a Pod.
