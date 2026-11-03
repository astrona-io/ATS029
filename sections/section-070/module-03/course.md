---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# ServiceAccount Tokens And API Access

A ServiceAccount proves who a pod is by giving it a token. A token is a signed JSON Web Token (JWT) that the API server accepts as the identity of the account. This module shows where tokens come from, how long they live, what they contain and how a pod uses one to call the Kubernetes API. It also shows the second half that every exam task needs: a token only identifies the account, and a Role and a RoleBinding decide what the account may do.

Keep one sentence in mind for this module: **authentication says which ServiceAccount is calling, authorization says what it may do, and a new account may do almost nothing until you bind a Role to it.** You will request tokens with `kubectl create token`, read the claims inside a token, call the API server from a pod with `curl`, read a `403 Forbidden` response, grant exactly one permission with a Role and a RoleBinding, and test it with `kubectl auth can-i --as`.

The module has two parts. **ServiceAccount Tokens** covers projected tokens, `kubectl create token` with a duration and an audience, and the legacy token Secret. **Call The API As A ServiceAccount** covers the request from inside a pod, the `403` of an unbound account, the Role and RoleBinding that fix it, and the impersonation check.

## Learning objectives

After this module you can:

- Explain what a projected, bound ServiceAccount token is, who creates it and how it expires.
- Request a token with `kubectl create token`, set its duration and audience, and read its claims.
- Create a token Secret of type `kubernetes.io/service-account-token`, and say why it is the legacy choice.
- Call the Kubernetes API from a pod with `curl`, the mounted token and the mounted certificate authority file.
- Read a `403 Forbidden` message and name the user, the verb and the resource.
- Grant an account one permission with a Role and a RoleBinding, and test it with `kubectl auth can-i --as=system:serviceaccount:<namespace>:<name>`.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, `kubectl exec`, and what a ServiceAccount is and how a pod names one with `serviceAccountName`. You do not need to know RBAC (role-based access control); this module teaches the part you need.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The commands use `curl` inside a pod, and `jq`, `base64`, `tr` and `awk` on your own machine to print token claims.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` and `probe` Deployments (`podinfo`), the `shuttle` Deployment (`curl`) and a `regcred` Secret. Every workload runs as the `default` ServiceAccount, which has no permission to list pods |
| `outpost` | The `drifter` client, also running as `default` |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
