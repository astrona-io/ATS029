# Overview: Create Secrets With kubectl And YAML (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with two namespaces, two small workloads and one existing Secret, and then waits. There is no task, no `astrona submit` and no pass or fail. Create Secrets, break them, run `astrona destroy`, and start over.

## What is in the environment

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | The `scout` Deployment (a `busybox` container that sleeps) and the Secret `scout-legacy` with the keys `username` and `password` |
  | `outpost` | The `drifter` Deployment (a `busybox` container that sleeps) and no Secrets |

## Helpers

Paste this once in each new terminal. `secret_value` prints one decoded value from a Secret, so you can check exactly what was stored. The `od` command in the second helper shows the bytes, which makes a trailing newline visible.

```sh
secret_value() {
  kubectl -n "$1" get secret "$2" -o jsonpath="{.data.$3}" | base64 --decode
}
secret_bytes() {
  secret_value "$1" "$2" "$3" | od -c
}
```

Use them like this: `secret_value starfleet scout-legacy password` and `secret_bytes starfleet scout-legacy password`.

## Practice tasks

- Create a Secret from two literal values, then decode both values with `secret_value`.
- Create the same Secret once with `echo` and once with `echo -n` piped through `base64` into a YAML file, apply both under different names, and compare them with `secret_bytes`.
- Create a Secret from a file and from an environment file, and compare the keys each one produces.
- Create a `docker-registry` Secret, decode `.dockerconfigjson` and find the `auth` field.
- Write a Secret with `stringData`, apply it, and confirm that `kubectl get secret -o yaml` shows only `data`.
- Make a Secret immutable, then try to change it and read the error.
- Create a Secret in `starfleet` and try to read it in `outpost`.
