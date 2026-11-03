---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Seccomp And A Read-Only Root Filesystem

A compromised application does its damage through the kernel: it calls the kernel to open files, start programs and change settings. Two settings in the `securityContext` shrink what such an application can do. A seccomp profile limits the system calls the process may make, and a read-only root filesystem stops the process from changing the files of its own image. This part tests both on a running pod and shows what breaks when an application needs to write.

## Seccomp

A **system call** is a request from a process to the Linux kernel, for example to open a file or to create a process. **Seccomp** (secure computing mode) is a kernel feature that filters system calls: a profile lists which calls the kernel allows, and the kernel blocks or logs the others. A Linux container normally makes only a small part of the several hundred system calls that exist, so a profile removes calls that the application never needs and that an attacker might use.

The field `seccompProfile` takes a `type`:

- `RuntimeDefault` uses the default profile of the container runtime (containerd in `kind`). It blocks a list of dangerous calls and allows what ordinary applications use.
- `Unconfined` turns the filter off.
- `Localhost` loads a profile file from the node. A second field, `localhostProfile`, names the file relative to the kubelet's seccomp directory.

The field is valid at pod level, where it is the default for all containers, and at container level, where it overrides the pod value. A pod that sets nothing runs unconfined, unless the kubelet was started with the `SeccompDefault` option, which makes `RuntimeDefault` the default for every pod without a profile.

## Read the seccomp state of a process

The kernel reports the seccomp state of a process in the file `/proc/<pid>/status`. The line `Seccomp:` shows `0` when no filter is active and `2` when a filter is active. Save this as `pods-seccomp.yaml`. It creates one pod with the runtime default profile and one pod with the filter turned off:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-runtime
  namespace: starfleet
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-unconfined
  namespace: starfleet
spec:
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        seccompProfile:
          type: Unconfined
```

Apply it:

```sh
kubectl apply -f pods-seccomp.yaml
kubectl -n starfleet wait --for=condition=Ready pod/seccomp-runtime pod/seccomp-unconfined --timeout=90s
```

Then read the seccomp line in each pod:

```sh
kubectl -n starfleet exec seccomp-runtime -- grep '^Seccomp:' /proc/1/status
kubectl -n starfleet exec seccomp-unconfined -- grep '^Seccomp:' /proc/1/status
```

The first pod shows `2`: the container runtime installed its default filter. The second pod shows `0`: no filter. Run the same `grep` in `shuttle`, which sets no profile. It shows `0` in a standard `kind` cluster, because the kubelet does not make `RuntimeDefault` the default there. If it shows `2`, the node has the `SeccompDefault` option on.

The `Localhost` type needs a profile file on the node, and the pod fails to start if the file is missing. The status of such a pod shows `CreateContainerError`. Use `RuntimeDefault` unless a security team gives you a named profile.

## A read-only root filesystem

Each container has a root filesystem built from its image layers, with a writable layer on top. The container field `readOnlyRootFilesystem: true` mounts that root filesystem read-only. A process that gets code execution can then no longer replace a program file or drop a script in the image. The field is valid at container level only.

Applications write files for good reasons: temporary files, caches, sockets, process ID files. If the root filesystem is read-only, those writes fail with `Read-only file system`. The fix is to mount a writable volume at exactly the paths that need it, and to leave the rest of the filesystem read-only. An `emptyDir` volume is the usual choice. It is an empty directory that Kubernetes creates on the node when the pod starts, and it lives as long as the pod.

Save this as `pod-readonly-root.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readonly-root
  namespace: starfleet
spec:
  volumes:
    - name: scratch
      emptyDir: {}
  containers:
    - name: main
      image: docker.io/library/busybox:1.37.0
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        readOnlyRootFilesystem: true
      volumeMounts:
        - name: scratch
          mountPath: /tmp
```

Apply it:

```sh
kubectl apply -f pod-readonly-root.yaml
kubectl -n starfleet wait --for=condition=Ready pod/readonly-root --timeout=60s
```

Then try to write in the root filesystem and in the volume:

```sh
kubectl -n starfleet exec readonly-root -- touch /rootfile
kubectl -n starfleet exec readonly-root -- touch /tmp/scratchfile
```

The first command fails with `Read-only file system` and a non-zero exit code. The second command succeeds, because `/tmp` is the `emptyDir` mount and the field applies to the root filesystem only. A volume mount is read-only only if its `volumeMount` sets `readOnly: true`.

## Find the path an application needs

An exam task often gives you a Deployment that crashes after you add `readOnlyRootFilesystem: true`. The container logs name the path that the application tried to write. Read them with `kubectl logs deployment/<name>`, look for `Read-only file system`, and mount an `emptyDir` at the directory in the message, not at `/`. Repeat until the application starts. Mount the smallest directory that works, so the rest of the image stays protected.

> [!TIP]
> After you add `readOnlyRootFilesystem: true` to a workload, always read `kubectl logs` and `kubectl get pods` before you move on. A pod that crashes right away almost always names the path it could not write.

You now know how to limit the system calls of a container and how to protect the image files while still giving the application the directories it writes to. The open question is what a pod can reach outside its own container: the network of the node, the files of the node, and the kernel parameters.

## Common pitfalls

> [!WARNING]
> - **Mounting a volume over `/` to make the application start.** A volume cannot replace the root filesystem. Mount a writable volume at the specific directory that the logs name.
> - **Expecting `readOnlyRootFilesystem` to make volumes read-only.** It applies to the root filesystem only. Set `readOnly: true` on a `volumeMount` to protect a volume.
> - **Assuming a pod without `seccompProfile` is filtered.** A pod that sets nothing runs unconfined unless the node enables `SeccompDefault`. Set `RuntimeDefault` explicitly.
> - **Using `Localhost` without a profile file on the node.** The container does not start, and the status shows `CreateContainerError`.
> - **Putting `readOnlyRootFilesystem` at pod level.** The field exists at container level only.
