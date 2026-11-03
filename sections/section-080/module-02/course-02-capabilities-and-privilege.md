---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Capabilities, Privilege Escalation And Privileged Containers

Running as a non-root user is not the only way to limit a process. A process that runs as root can still be limited, because Linux splits the power of root into smaller units. This part explains those units, called capabilities, and two container settings that decide how much power a process can ever have: `allowPrivilegeEscalation` and `privileged`. Each setting is tested with a command that needs the power.

## Linux capabilities

A **Linux capability** is one named permission for one kind of privileged operation. Root is not one permission; the kernel checks a specific capability for each operation. `CAP_CHOWN` allows changing the owner of any file. `CAP_NET_BIND_SERVICE` allows listening on a port below 1024. `CAP_NET_RAW` allows raw network sockets. `CAP_SYS_ADMIN` allows a very wide set of administration operations. It is so wide that a container should almost never hold it.

The container runtime (containerd in `kind`) starts every container with a default set of capabilities. The set is smaller than the full set of root, and it still includes `CHOWN`, `NET_BIND_SERVICE`, `NET_RAW`, `SETUID`, `SETGID` and `KILL`. The `securityContext` of a container can change that set with the `capabilities` field:

- `drop` lists capabilities to remove. The special value `ALL` removes every capability.
- `add` lists capabilities to add back.

Kubernetes writes the names without the `CAP_` prefix: `CHOWN`, not `CAP_CHOWN`. The container runtime removes the `drop` entries first and then applies the `add` entries. The field `capabilities` exists at container level only, because a pod-level value would not say which container needs what.

## Show the effect of dropping a capability

The command `chown` needs `CAP_CHOWN`. Save this as `pods-capabilities.yaml`. It creates three pods that run as root. The first keeps the default set, the second drops all capabilities, and the third drops all and adds back only `CHOWN`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: caps-default
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: caps-dropped
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        capabilities:
          drop: ["ALL"]
---
apiVersion: v1
kind: Pod
metadata:
  name: caps-chown
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        capabilities:
          drop: ["ALL"]
          add: ["CHOWN"]
```

Apply it and wait for the pods:

```sh
kubectl apply -f pods-capabilities.yaml
kubectl -n starfleet wait --for=condition=Ready pod/caps-default pod/caps-dropped pod/caps-chown --timeout=90s
```

Then run the same command in each pod. It creates a file and changes its owner to user 1234:

```sh
kubectl -n starfleet exec caps-default -- sh -c 'touch /tmp/f && chown 1234 /tmp/f && echo chown worked'
kubectl -n starfleet exec caps-dropped -- sh -c 'touch /tmp/f && chown 1234 /tmp/f && echo chown worked'
kubectl -n starfleet exec caps-chown -- sh -c 'touch /tmp/f && chown 1234 /tmp/f && echo chown worked'
```

The first and the third pod print `chown worked`. The second pod prints an error that says `Operation not permitted`, and the command exits with a non-zero code. All three run as root, so the user is the same; only the capability set differs. This is the exam skill: grant the one capability the application needs and drop the rest.

You can read the capability mask of the main process directly. The kernel reports it in the line that starts with `CapEff` (effective capabilities) in `/proc/1/status`:

```sh
kubectl -n starfleet exec caps-default -- grep CapEff /proc/1/status
kubectl -n starfleet exec caps-dropped -- grep CapEff /proc/1/status
```

The mask of `caps-default` has several bits set. The mask of `caps-dropped` is all zeros, which means the process holds no capability at all. The mask is a hexadecimal number where each bit is one capability, so you do not need to decode it. A zero mask is the target for an application that needs no privileged operation.

## allowPrivilegeEscalation

Some programs gain privilege when they run. A program file with the setuid bit runs as its file owner, which can be root, no matter who started it. A program with file capabilities can gain capabilities in the same way. **Privilege escalation** means a process gains more privilege than its parent process had.

The container field `allowPrivilegeEscalation` controls this. When it is `false`, the container runtime sets the Linux flag `no_new_privs` on the process. The kernel then ignores setuid bits and file capabilities for that process and for its children. When the field is not set, the default is `true`.

Save this as `pod-no-escalation.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-escalation
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        allowPrivilegeEscalation: false
```

Apply it and read the flag from the kernel:

```sh
kubectl apply -f pod-no-escalation.yaml
kubectl -n starfleet wait --for=condition=Ready pod/no-escalation --timeout=60s
kubectl -n starfleet exec no-escalation -- grep NoNewPrivs /proc/1/status
```

The line ends with `1`: the flag is on. Run the same `grep` in `caps-default` and the line ends with `0`. The field is valid at container level only. It is always `true` for a container that runs as `privileged` or that holds `CAP_SYS_ADMIN`, because those containers can already do anything.

## Privileged containers

A container with `privileged: true` is the opposite of everything above. The runtime gives the process all capabilities, access to all host devices, and a relaxed system call and mandatory access control profile. Root inside such a container is close to root on the node. Use it only for node-level system components, such as a network plugin.

Save this as `pod-privileged-escalation.yaml`. It asks for two things that exclude each other:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-conflict
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        privileged: true
        allowPrivilegeEscalation: false
```

Apply it:

```sh
kubectl apply -f pod-privileged-escalation.yaml
```

The API server rejects the pod with an `Invalid value` error that says the container cannot set `allowPrivilegeEscalation` to `false` and `privileged` to `true`. The rejection comes from API validation of the pod object, before any admission policy or scheduler runs. Remove `allowPrivilegeEscalation` and the pod is accepted, with `allowPrivilegeEscalation` forced on.

You now know which three container settings remove privilege: the capability set, `allowPrivilegeEscalation` and `privileged`. A hardened container combines them: a numeric non-root user, `drop: ["ALL"]` and `allowPrivilegeEscalation: false`. The open question is how to prove a given pod is configured that way when you only have the cluster, and how to write the fields fast under exam time pressure.

When you must write a `securityContext` from memory, ask `kubectl explain` for the field list. For example, `kubectl explain pod.spec.containers.securityContext --recursive` prints every field with its type, so you do not have to remember which fields are valid at which level.

## Common pitfalls

> [!WARNING]
> - **Writing `CAP_NET_ADMIN` in the manifest.** Kubernetes expects `NET_ADMIN`, without the `CAP_` prefix.
> - **Writing `add` without `drop`.** `add` only extends the default set. To end with a small set, write `drop: ["ALL"]` and then `add` the one capability.
> - **Putting `capabilities` or `allowPrivilegeEscalation` at pod level.** Both are valid at container level only.
> - **Setting `privileged: true` to fix a permission error.** It removes nearly every limit. Find the one capability or the file ownership that the process needs instead.
> - **Treating non-root as the same thing as no capabilities.** A non-root process and a process with an empty capability set are two separate controls. Check both.
