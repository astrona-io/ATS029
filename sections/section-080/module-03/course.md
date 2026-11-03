---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Seccomp, Host Access And Pod Security Admission

A container shares the kernel of its node with every other container on that node. The settings in this module decide how much of that kernel the container can reach: which system calls it may make, whether it can write to its own filesystem, whether it can see the node's network and files, and which kernel parameters it may change. The Pod Security Admission controller then checks these settings when a pod is created and rejects pods that go too far. On the CKAD exam you meet this as a Deployment that creates no pods, and you must find the reason and fix the pod template.

Keep one sentence in mind for this module: **a pod must ask for the least access to the node that the application needs, and a namespace label can reject pods that ask for more.** You will test seccomp and a read-only root filesystem, then host network, host paths and sysctls, and then fix a Deployment that a namespace rejects.

## Learning objectives

After this module you can:

- Set a seccomp profile at pod and container level and read the effect from the process status.
- Run a container with `readOnlyRootFilesystem: true` and give it writable paths with `emptyDir` volumes.
- Explain what `hostNetwork`, `hostPID`, `hostIPC` and `hostPath` give a pod, and which Pod Security level rejects them.
- Set a safe sysctl on a pod and explain why an unsafe sysctl leaves the pod in a failed state.
- Label a namespace with the Pod Security Admission modes and levels, and list the settings the `restricted` level requires.
- Find the rejection of a Deployment in the events of its ReplicaSet and fix the pod template without weakening the namespace.

## Before you start

You need Kubernetes basics: pods, Deployments, ReplicaSets, namespaces, volumes, labels, and the commands `kubectl apply`, `kubectl get`, `kubectl describe`, `kubectl exec` and `kubectl label`. You need no policy engine; Pod Security Admission is built into the API server.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | No Pod Security labels. `scout` runs `podinfo` and `shuttle` runs `busybox`. Neither has a `securityContext` |
| `outpost` | Labelled `pod-security.kubernetes.io/enforce: baseline` and `pod-security.kubernetes.io/warn: restricted`. `drifter` runs `busybox` |

`kubectl` already points at the playground cluster, as the cluster administrator.

The module has three parts. **Seccomp And A Read-Only Root Filesystem** limits the system calls and the writes of one container. **Host Access And Sysctls** shows what a pod gets from the node and from the kernel parameters. **Pod Security Admission And A Rejected Deployment** shows how a namespace label rejects pods and how to fix a workload that it rejects.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
