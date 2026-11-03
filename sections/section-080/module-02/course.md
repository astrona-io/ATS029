---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Users, Groups, Capabilities And Privilege

A container is a Linux process, and Linux decides what a process may do from three facts: the user and group it runs as, the capabilities it holds, and whether it may gain more privilege later. Kubernetes exposes all three in the `securityContext` field of a pod and of each container. On the CKAD exam you must set these fields quickly, predict which value wins when the pod level and the container level disagree, and explain why a volume has the owner it has.

Keep one sentence in mind for this module: **the `securityContext` sets the identity and the privilege of the container process, and the container-level value wins over the pod-level value.** You will check the identity of running pods, build the numeric user, group and volume ownership settings, and then remove privilege step by step with capabilities, `allowPrivilegeEscalation` and `privileged`.

## Learning objectives

After this module you can:

- Set `runAsUser`, `runAsGroup`, `runAsNonRoot`, `fsGroup` and `supplementalGroups`, and say which are valid at pod level and which at container level.
- Predict the effective user and group of a container when both levels set a value.
- Explain why a volume is owned by the `fsGroup` group and why a file created in it gets that group.
- Explain why the kubelet refuses `runAsNonRoot: true` for an image whose user is a name and not a number.
- Add and drop Linux capabilities, and show the effect with a command that needs one.
- Explain what `allowPrivilegeEscalation` and `privileged` change, and why they cannot be combined as `false` and `true`.

## Before you start

You need Kubernetes basics: pods, Deployments, volumes, and the commands `kubectl apply`, `kubectl get`, `kubectl describe` and `kubectl exec`. You do not need to know Linux capabilities or user IDs; the parts explain them.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout` runs the `podinfo` image, whose image user is the named user `app`. `shuttle` runs `busybox` as root. Neither has a `securityContext`. No Pod Security labels are set |

`kubectl` already points at the playground cluster, as the cluster administrator.

The module has two parts. **User, Group And Volume Ownership** explains the numeric identity fields, the pod and container precedence, and the ownership of volumes. **Capabilities, Privilege Escalation And Privileged Containers** removes Linux privilege from a container and shows the effect of each setting.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
