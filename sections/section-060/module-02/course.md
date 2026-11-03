---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Create Secrets With kubectl And YAML

A Secret is a Kubernetes object that holds a small amount of sensitive data, such as a password, a token or a private key. Before any pod can use that data, someone must create the Secret in the right namespace, with the right type and the right keys. On the Certified Kubernetes Application Developer (CKAD) exam you do this from the terminal, fast, and a wrong key name or a stray newline means the application still fails.

Keep one sentence in mind for this module: **a Secret is a named set of keys and values in one namespace, and its type decides which keys must exist.** You will create Secrets with each `kubectl create secret` form, read the values back, write the same object as YAML with `stringData`, and make a Secret immutable.

The module has two parts. **Creating Generic Secrets** covers `kubectl create secret generic` with literal values, files and environment files, base64 encoding and the newline mistake. **Secret Types, stringData And Immutability** covers the built-in types, the `tls` and `docker-registry` forms, the difference between `data` and `stringData`, and the `immutable` field.

## Learning objectives

After this module you can:

- Create a Secret with `kubectl create secret generic` from literal values, from files and from an environment file.
- Read a stored value back and decode it, and explain why base64 is an encoding and not protection.
- Create `tls` and `docker-registry` Secrets and name the keys each type requires.
- Write a Secret as YAML with `stringData` and explain how the API server turns it into `data`.
- Make a Secret immutable and explain how to change a value afterward.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl delete`. You need the `base64` and `openssl` commands on your own machine for the `tls` example.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` Deployment, which runs a `busybox` container, and a Secret named `scout-legacy` with a `username` and a `password` key |
| `outpost` | The `drifter` Deployment, which runs a `busybox` container, and no Secrets |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
