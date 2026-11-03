---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Admission Control: Mutation, Defaults, Quotas And Policies

A user can have a valid identity and the right to create Deployments, and the API server can still refuse a particular Deployment. The refusal comes from admission control, the last check before the API server stores an object. In the CKAD exam, admission shows up as a pod that no longer starts, a quota that blocks a new object, or a policy that rejects a manifest. This module teaches you to see which admission step acted, to read its message, and to write a policy yourself.

The module has three parts. The first explains the order of the checks and the difference between mutating and validating admission. The second covers the built-in plugins `LimitRanger`, `ResourceQuota` and `NamespaceLifecycle`, and the server-side dry run that previews their decisions. The third writes a `ValidatingAdmissionPolicy` with a Common Expression Language (CEL) rule and a binding that scopes it to a namespace.

## Learning goals

After this module you can:

- Place authentication, authorization, mutating admission, schema validation and validating admission in order.
- Show a change that a mutating admission plugin made to an object, and a rejection that a validating one made.
- Set defaults and limits with a `LimitRange` and read a `ResourceQuota` rejection.
- Preview a request with `--dry-run=server` without storing anything.
- Write a `ValidatingAdmissionPolicy` and a `ValidatingAdmissionPolicyBinding`, and read the rejection message.

## Before you start

You need to know pods, Deployments, namespaces, resource requests and limits, and `kubectl apply`. You do not need to know CEL; the third part introduces the few expressions that it uses.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` Deployment (busybox), with no resource requests or limits |
| `outpost` | The `drifter` Deployment (busybox), with no resource requests or limits |

No `LimitRange`, `ResourceQuota` or policy exists at the start.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
