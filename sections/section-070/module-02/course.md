---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Create And Assign ServiceAccounts

A pod in Kubernetes never runs "as nobody". The API server gives every pod exactly one ServiceAccount, and that account is the identity the pod uses when it talks to the Kubernetes API. If you do not choose one, the pod gets the `default` ServiceAccount of its namespace. This module teaches you to choose the account on purpose: to create ServiceAccounts, to assign them to pods and Deployments, to decide whether a pod receives an API token at all, and to attach registry credentials to an account.

Keep one sentence in mind for this module: **the pod template names one ServiceAccount from its own namespace, the API server fixes that choice when the pod is created, and the account decides which credentials the pod gets.** You will read the account an existing pod already uses, create new accounts with `kubectl create serviceaccount`, change a Deployment with `kubectl set serviceaccount`, switch the token mount off, and put an image pull secret on an account.

The module has two parts. **Create And Assign A ServiceAccount** covers the `default` account, the `serviceAccountName` field, `kubectl set serviceaccount` and what happens when the named account does not exist. **Token Mounting And Image Pull Secrets** covers `automountServiceAccountToken` on the account and on the pod, and `imagePullSecrets` on the account.

## Learning objectives

After this module you can:

- Read which ServiceAccount a running pod uses, and explain why a pod without a choice uses `default`.
- Create a ServiceAccount with `kubectl create serviceaccount` and from YAML.
- Assign a ServiceAccount with `spec.serviceAccountName` and with `kubectl set serviceaccount`.
- Explain why a pod cannot change its account and cannot use an account from another namespace.
- Switch off the token mount with `automountServiceAccountToken` on an account or on a pod, and say which setting wins.
- Attach `imagePullSecrets` to a ServiceAccount and check that new pods receive them.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, and the commands `kubectl get`, `kubectl apply`, `kubectl describe`, `kubectl patch` and `kubectl rollout`. You do not need to know RBAC (role-based access control) yet. The module only creates identities; it does not give them permissions.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The `jq` tool is used once to read JSON.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` and `probe` Deployments (`podinfo`), the `shuttle` Deployment (`curl`) and a `regcred` Secret with a registry credential for practice. Every workload runs as the `default` ServiceAccount |
| `outpost` | The `drifter` client, also running as `default` |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
