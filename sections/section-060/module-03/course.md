---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Consume Secrets In Pods

Creating a Secret does nothing for an application until a pod receives the data. Kubernetes gives a pod three ways to use a Secret: as environment variables, as files in a mounted volume, and, for a private registry login, as an image pull credential that the kubelet uses before the container starts. Each way has its own failure messages and its own rule for what happens when the Secret changes. The CKAD exam asks you to wire Secrets into a Deployment from the terminal, and to reason about who else can read them.

Keep one sentence in mind for this module: **a pod receives a Secret only through its own spec, and a running container never sees a changed Secret unless the delivery method supports it.** You will inject keys as environment variables, mount a Secret as files with chosen permissions, add an image pull Secret, and then limit who may read Secrets with RBAC (role-based access control).

The module has three parts. **Secrets As Environment Variables** covers `secretKeyRef`, `envFrom`, the error a missing Secret causes and why a running container keeps the old value. **Secrets As Volumes And Pull Credentials** covers volume mounts, `items`, `defaultMode`, projected volumes, update delays and `imagePullSecrets`. **Access Control And The Limits Of Secrets** covers RBAC rules for Secrets, indirect access through pods, why base64 is not encryption, and encryption at rest.

## Learning objectives

After this module you can:

- Inject one key with `secretKeyRef` and all keys with `envFrom`, with and without a prefix.
- Read the `CreateContainerConfigError` status and name the missing Secret or key from the pod events.
- Mount a Secret as a read-only volume with `items` and `defaultMode`, and explain when a mounted Secret updates.
- Reference an image pull Secret from a pod and from a ServiceAccount.
- Write a Role that allows reading one named Secret, and test it with `kubectl auth can-i`.
- Explain why base64 is not encryption, who can read a Secret indirectly, and what encryption at rest changes.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, ServiceAccounts, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl exec`. You need to know how to create a Secret with `kubectl create secret`.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The Deployments `scout` and `probe` (each a `busybox` container that sleeps), the ServiceAccounts `scout`, `probe` and `auditor`, and three Secrets: `bridge-credentials` (keys `username` and `password`), `bridge-certificate` (keys `tls.crt` and `tls.key`) and `bridge-registry` (a registry login) |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
