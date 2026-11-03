# Overview: Authentication And kubeconfig (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Create users, switch contexts, break things, run `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it with the cluster administrator credentials.
- You need `openssl` on your own machine to create private keys and certificate signing requests.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | A `scout` Deployment running `busybox:1.37.0` and a ServiceAccount named `shuttle` |
  | `outpost` | A `drifter` Deployment running `busybox:1.37.0` |

  No Role, RoleBinding or user other than the cluster administrator exists.

## Ideas to try

- Run `kubectl auth whoami` and read the username and groups of your own credentials.
- Create a token for the `shuttle` ServiceAccount with `kubectl -n starfleet create token shuttle` and call `kubectl --token=... auth whoami`.
- Create a private key and a certificate signing request for a user, approve it with `kubectl certificate approve`, and build a context for the user with `kubectl config set-credentials` and `kubectl config set-context`.
- Try the new context before you bind any Role, then bind a read-only Role and try again. Compare the two `Forbidden` messages.
- Deny a certificate signing request with `kubectl certificate deny` and look at its conditions.
- Add `--namespace` to a context and check how `kubectl get pods` changes.
