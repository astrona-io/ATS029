# Overview: Consume Secrets In Pods (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with one namespace, three Secrets and two small Deployments that use none of them yet, and then waits. There is no task, no `astrona submit` and no pass or fail. Wire the Secrets in, break the references on purpose, run `astrona destroy`, and start over.

## What is in the environment

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.

  | Object in `starfleet` | What it is |
  | --- | --- |
  | `bridge-credentials` | Secret with the keys `username` and `password` |
  | `bridge-certificate` | Secret with the keys `tls.crt` and `tls.key` (placeholder text, not a real certificate) |
  | `bridge-registry` | Secret of type `kubernetes.io/dockerconfigjson` for `registry.starfleet.example` |
  | `scout`, `probe` | Deployments with a `busybox` container that sleeps, each with its own ServiceAccount |
  | `auditor` | ServiceAccount with no permissions |

## Helpers

Paste these once in each new terminal. `pod_env` prints one environment variable of a Deployment's pod. `pod_file` prints the permission mode and the content of one file in a pod. `can_read` asks whether the `auditor` ServiceAccount may perform a verb on a resource.

```sh
pod_env() {
  kubectl -n starfleet exec "deploy/$1" -- printenv "$2"
}
pod_file() {
  kubectl -n starfleet exec "deploy/$1" -- sh -c "stat -L -c '%a' '$2'; cat '$2'; echo"
}
can_read() {
  kubectl -n starfleet auth can-i "$1" "$2" --as=system:serviceaccount:starfleet:auditor
}
```

Use them like this: `pod_env scout BRIDGE_PASSWORD`, `pod_file shuttle /etc/shuttle/credentials/password` and `can_read get secret/bridge-credentials`.

## Practice tasks

- Add `BRIDGE_USER` and `BRIDGE_PASSWORD` to `scout` with two `secretKeyRef` entries, then do the same with one `envFrom` entry and a prefix.
- Point a `secretKeyRef` at a key that does not exist and read the pod events. Then add `optional: true` and compare.
- Rotate the password in `bridge-credentials` and watch which of `scout` (environment) and a pod with a mounted volume sees the new value, and when.
- Mount `bridge-certificate` into `probe` with only `tls.key` listed in `items` and `defaultMode: 0400`. Check the mode with `pod_file`.
- Add `bridge-registry` to `imagePullSecrets` on the `scout` ServiceAccount and restart `scout` to see the field in the new pod.
- Give `auditor` a Role that allows `get` on one Secret, then try `list` and a second Secret with `can_read`.
