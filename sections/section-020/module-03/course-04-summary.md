---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Summary

Admission control is the last check before the API server stores an object. It applies to requests that create, update or delete, and it runs after authentication and authorization. Mutating steps run first and can change the object. The API server then validates the object against its schema, and validating steps run last and can only accept or reject. Because validating steps run last, they judge the final object, including everything that mutating steps added.

Built-in plugins do much of this work. The `ServiceAccount` plugin sets the service account and the token volume, and `DefaultTolerationSeconds` adds tolerations. `LimitRanger` writes default requests and limits into containers and rejects containers outside the minimum and maximum of a LimitRange. `ResourceQuota` rejects a request that would take a namespace over its quota, and `NamespaceLifecycle` rejects objects in a missing or terminating namespace. These plugins act when a pod is created, so a new LimitRange does not change running pods, and a quota rejection for a Deployment appears as a `FailedCreate` event on its ReplicaSet.

The flag `--dry-run=server` sends the full request through admission without storing anything, so it shows mutations and rejections. The flag `--dry-run=client` never reaches admission. A `ValidatingAdmissionPolicy` adds a rule of your own, written in CEL, that the API server evaluates without a webhook server. A `ValidatingAdmissionPolicyBinding` turns it on for selected namespaces and sets the actions `Deny`, `Warn` or `Audit`. The rejection message names the policy and the binding.

Key facts to remember:

- Both RBAC and admission errors say `Forbidden`; read the rest of the message.
- Admission judges the object, so the cluster administrator is rejected too.
- A policy with no binding, or a binding with only `Warn`, rejects nothing.
- List `UPDATE` in the policy operations, and remember that `kubectl scale` uses the `scale` subresource.
- Test with `--dry-run=server`, and allow a few seconds after creating a binding.

<!-- astrona:playground:destroy -->
