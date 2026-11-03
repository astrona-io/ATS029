# Overview: Create And Assign ServiceAccounts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Create accounts, assign them, break the assignment, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `scout` and `probe` (`podinfo`), `shuttle` (`curl`) and the Secret `regcred` (a registry credential for practice). Every workload runs as the `default` ServiceAccount and receives a token |
  | `outpost` | The `drifter` client, running as `default` |

## Helpers

Paste these once in each new terminal. `pod_account` prints the account of each pod of an app. `pod_volumes` prints the volume names of each pod of an app, so you can see whether a token volume exists.

```sh
pod_account() {
  kubectl -n "$1" get pods -l "app=$2" -o custom-columns=NAME:.metadata.name,ACCOUNT:.spec.serviceAccountName
}
pod_volumes() {
  kubectl -n "$1" get pods -l "app=$2" -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.volumes[*].name}{"\n"}{end}'
}
```

Use them like this: `pod_account starfleet scout`, `pod_volumes starfleet probe`.

## Practice tasks

- Create an account called `bridge` in `outpost` with `kubectl create serviceaccount`, and print it as YAML.
- Make `drifter` use `bridge` with `kubectl set serviceaccount`. Check the pod after the rollout.
- Point `shuttle` at an account that does not exist. Find the error in the ReplicaSet events, then fix it.
- Try to name `bridge` (which exists only in `outpost`) in a `starfleet` Deployment. Read the error.
- Set `automountServiceAccountToken: false` on the `scout` account and on the `probe` pod template. Compare the volumes before and after.
- Add `regcred` to an account and compare the `imagePullSecrets` of a pod created before and after the change.
