---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Authentication, Client Certificates And kubeconfig

Every request to the Kubernetes API server starts with one question: who is sending it? The API server answers that question before it looks at permissions. If it cannot answer, it returns `401 Unauthorized` and the request goes no further. In the CKAD exam you often receive a task that begins with a new person or a new application: create the credentials, add them to the `kubeconfig` file, and prove that the access is narrow. This module teaches that whole path with `kubectl` only.

The module has three parts. The first explains how the API server turns a credential into a username and groups. The second creates a client certificate through a `CertificateSigningRequest`. The third builds `kubeconfig` contexts and checks access with `kubectl auth can-i`, `kubectl auth whoami` and impersonation.

## Learning goals

After this module you can:

- Name the credential types the API server accepts and say which part of each becomes the username and the groups.
- Read your own identity with `kubectl auth whoami` and tell a `401` from a `403`.
- Create a private key and a certificate signing request with `openssl`, submit it as a `CertificateSigningRequest`, approve it and extract the signed certificate.
- Build a user, a cluster and a context in a `kubeconfig` file with `kubectl config`, and switch between contexts.
- Check what an identity may do with `kubectl auth can-i`, `--as` and `--as-group`.

## Before you start

You need to know what a namespace, a pod and a Role are, and how to run `kubectl get` and `kubectl apply`. You do not need to know how certificates work internally; the first two parts explain what you need. You need `openssl` on your own machine.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, with the credentials of the cluster administrator.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` Deployment (busybox) and the ServiceAccount `shuttle` |
| `outpost` | The `drifter` Deployment (busybox) |

No Role, RoleBinding or user other than the cluster administrator exists at the start.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
