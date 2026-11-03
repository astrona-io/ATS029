# Overview: Consuming ConfigMaps (Playground)

This is a playground, not a lab. It starts a fresh cluster with one ConfigMap and one idle pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Write pods, break them, delete them and start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The ConfigMap `scout-settings` with the keys `LOG_LEVEL` (`info`), `REGION` (`outpost-7`), `app.properties` (two lines) and `banner.txt` (one line), and a `viewer` Deployment with one `busybox` pod for `kubectl exec` |

## Helpers

Paste these once in each new terminal. `show_env` prints the environment variables of a pod that match a pattern. `show_events` prints the events of one pod, which is where `CreateContainerConfigError`, `FailedMount` and `InvalidEnvironmentVariableNames` appear.

```sh
show_env() {
  kubectl -n starfleet exec "$1" -- printenv | grep -E "$2"
}
show_events() {
  kubectl -n starfleet get events --field-selector involvedObject.name="$1"
}
```

Use them like this: `show_env probe-env LOG`, `show_events probe-missing`.

## Practice tasks

- Write a pod that sets `PROBE_REGION` from the key `REGION` with `configMapKeyRef`. Check the value with `show_env`.
- Load the whole ConfigMap with `envFrom` and a prefix. Predict which keys are skipped, then read the events.
- Point `configMapKeyRef` at a key that does not exist. Read the status, then add `optional: true` and compare.
- Mount `scout-settings` as a volume. Then mount only `app.properties` as `probe.conf` with `mode: 0400`, and check the permissions with `stat -L -c '%a'`.
- Mount `banner.txt` with `subPath`, change the key, and find out which mount updates and how long it takes.
- Create a second ConfigMap and merge both into one directory with a `projected` volume.
- Create a Deployment that uses `envFrom`, change the ConfigMap, and compare `kubectl rollout restart` with changing the ConfigMap name.
