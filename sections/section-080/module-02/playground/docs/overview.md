# Overview: Users, Groups, Capabilities And Privilege (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with two workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Create pods, change their `securityContext`, break them, run `astrona destroy`, and start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. No Pod Security labels are set, so every pod is admitted.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` runs the `podinfo` image, whose image user is the named user `app`. `shuttle` runs `busybox` as root. Neither has a `securityContext` |

## Helpers

Paste these once in each new terminal. `ids` prints the user, group and supplementary groups of the first container of a pod. `caps` prints the effective capability mask of a container's main process. `owner` prints the numeric owner and group of a path.

```sh
ids() {
  kubectl -n "$1" exec "$2" -- id
}
caps() {
  kubectl -n "$1" exec "$2" -- grep CapEff /proc/1/status
}
owner() {
  kubectl -n "$1" exec "$2" -- stat -c '%u:%g %a %n' "$3"
}
```

Use them like this: `ids starfleet deploy/shuttle`, `caps starfleet deploy/shuttle`, `owner starfleet deploy/shuttle /tmp`.

## Practice tasks

- Run `ids` on `shuttle`, then add `runAsUser: 2000` and `runAsGroup: 3000` at pod level and run it again. Predict the output first.
- Add a container-level `runAsUser` that differs from the pod-level value and find out which one wins.
- Create a pod with an `emptyDir` volume and `fsGroup: 4000`. Run `owner` on the mount path and read the group and the mode.
- Compare `caps` for a container with no `capabilities` field, with `drop: ["ALL"]`, and with `drop: ["ALL"]` plus `add: ["CHOWN"]`. Test each with `chown 1234 /tmp/file`.
- Set `privileged: true` and `allowPrivilegeEscalation: false` in the same container and read the error from the API server.
