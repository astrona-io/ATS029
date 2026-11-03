# Overview: Enforce Namespace Budgets With ResourceQuota (Playground)

This is a playground, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Create quotas, break them, delete them, run `astrona destroy` and start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. There is no metrics server, so `kubectl top` does not work.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` (`podinfo`), `probe` (`go-httpbin`) and `shuttle` (`curl`), one replica each, with small CPU and memory requests and a memory limit. The Services `scout` and `probe` |
| `outpost` | The `drifter` client, one replica, with small requests and a memory limit |

No ResourceQuota and no LimitRange exist in either namespace.

## Helpers

Paste these once in each new terminal. `quota_used` prints the hard and used values of every quota in a namespace. `quota_events` lists the `FailedCreate` events that a controller recorded because a quota refused a pod.

```sh
quota_used() {
  kubectl -n "$1" get resourcequota -o custom-columns='NAME:.metadata.name,HARD:.status.hard,USED:.status.used'
}
quota_events() {
  kubectl -n "$1" get events --field-selector reason=FailedCreate
}
```

Use them like this: `quota_used starfleet` and `quota_events starfleet`.

## Practice tasks

- Create a quota with `kubectl create quota` that limits `requests.cpu`, `requests.memory`, `limits.cpu` and `limits.memory` in `outpost`. Predict the `Used` column before you run `kubectl describe quota`.
- Run `kubectl -n outpost rollout restart deployment/drifter` with that quota in place. Find out why the new pod is refused and which message tells you.
- Create a quota with `count/deployments.apps` and `count/jobs.batch` limits in `starfleet`. Create objects until one is rejected, then read the three values in the message.
- Create a quota that uses the `NotBestEffort` scope and compare its used values with an unscoped quota.
- Lower a quota below its current use. Check that no pod is deleted, then run `kubectl -n starfleet rollout restart deployment/scout` and read what happens.
