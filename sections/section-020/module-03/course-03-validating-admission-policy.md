---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Write A ValidatingAdmissionPolicy

The built-in plugins have fixed rules. Sometimes a team needs its own rule: no more than three replicas in a namespace, no image with the tag `latest`, a required label on every Deployment. Before Kubernetes had a built-in way to write such rules, teams ran a webhook server for each one. A `ValidatingAdmissionPolicy` puts the rule in a Kubernetes object that the API server evaluates itself. This part writes one policy, binds it to a namespace, switches it from a warning to a rejection, and reads the result.

## Two objects, one rule

A **ValidatingAdmissionPolicy** is a cluster-scoped object that describes what to check and which requests to check. It does nothing by itself. A **ValidatingAdmissionPolicyBinding** is a second cluster-scoped object that turns a policy on for a set of namespaces and chooses what happens when the check fails. Splitting the two lets one policy have several bindings with different scopes and actions.

The policy has these fields:

- `matchConstraints` selects the requests: API groups, versions, operations such as `CREATE` and `UPDATE`, and resources.
- `validations` is a list of rules. Each has an `expression` written in the **Common Expression Language (CEL)**, a small expression language with no loops and no side effects. The expression must evaluate to `true` for the request to pass. Each rule has a `message` for the rejection.
- `failurePolicy` says what to do when the policy itself cannot be evaluated. `Fail` rejects the request. `Ignore` lets it through.

The binding has `policyName`, `validationActions` and `matchResources`. The actions are `Deny`, which rejects the request, `Warn`, which accepts it and returns a warning to the client, and `Audit`, which accepts it and writes an annotation to the audit log. You can set more than one.

## Write the policy

CEL sees the request through a few variables. The variable `object` is the new object, `oldObject` is the stored one on an update, and `request` holds request details such as the user. For a Deployment, `object.spec.replicas` is the replica count. Save this as `validatingadmissionpolicy-replica-limit.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.replicas <= 3"
      message: "A Deployment may not have more than 3 replicas."
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-replica-limit.yaml
```

Then check the result:

```sh
kubectl get validatingadmissionpolicy replica-limit
```

The list shows the policy and a count of parameter kinds, which is empty here. At this point nothing is enforced. A policy without a binding checks no request.

## Bind it to one namespace in warning mode

A binding selects namespaces with a label selector. Every namespace has the label `kubernetes.io/metadata.name` with its own name, so you can select one namespace by name. Start with the action `Warn`, so you can see what the rule would reject before it rejects. Save this as `validatingadmissionpolicybinding-replica-limit-outpost.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-outpost
spec:
  policyName: replica-limit
  validationActions: ["Warn"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: outpost
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicybinding-replica-limit-outpost.yaml
```

The API server needs a few seconds to compile the expression and start using the binding. Try a Deployment with five replicas in `outpost`, with a server-side dry run so that nothing is stored:

```sh
kubectl -n outpost create deployment bridge --image=busybox:1.37.0 --replicas=5 --dry-run=server
```

The command succeeds and prints a line that ends in `(server dry run)`. Above it, `kubectl` prints a `Warning` that names the policy `replica-limit`, the binding `replica-limit-outpost` and your message. If you see no warning, wait a few seconds and run the command again. The warning reached the client as a response header, which is why a script that ignores stderr never sees it.

## Switch to Deny and read the rejection

Change the action by editing the same file. Replace `["Warn"]` with `["Deny"]` in `validatingadmissionpolicybinding-replica-limit-outpost.yaml` and apply it again:

```sh
kubectl apply -f validatingadmissionpolicybinding-replica-limit-outpost.yaml
kubectl -n outpost create deployment bridge --image=busybox:1.37.0 --replicas=5 --dry-run=server
```

Now the command fails with `Forbidden`, or with an `invalid` error, depending on the `reason` field of the rule. The message starts with `ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-outpost' denied request`, followed by your text. The message names the policy and the binding, so you know which two objects to read. A rule can set `reason` to `Invalid`, `Forbidden`, `Unauthorized` or `RequestEntityTooLarge`; this changes the status code and the first words of the error, not the decision.

Three more checks show the limits of the scope:

```sh
kubectl -n outpost create deployment bridge --image=busybox:1.37.0 --replicas=3 --dry-run=server
kubectl -n starfleet create deployment bridge --image=busybox:1.37.0 --replicas=5 --dry-run=server
kubectl -n outpost patch deployment drifter --type=merge -p '{"spec":{"replicas":5}}' --dry-run=server
```

The first passes, because three is within the limit. The second passes, because the binding selects only `outpost`. The third fails, because the policy covers `UPDATE` as well as `CREATE`. Without `UPDATE` in `operations`, a user could create a valid Deployment and then change it to break the rule.

The command `kubectl scale` calls the `scale` subresource of the Deployment, and the policy rule above lists only `deployments`. A rule that must also catch scaling needs a second resource rule for `deployments/scale`, with an expression that reads `object.spec.replicas` of the `Scale` object. Always test the commands that people really use.

## Messages that carry the value

A fixed message tells the user the rule but not the value that broke it. A `messageExpression` field builds the message with CEL, so the error shows the actual number:

```yaml
validations:
  - expression: "object.spec.replicas <= 3"
    messageExpression: "'The Deployment asks for ' + string(object.spec.replicas) + ' replicas, and the limit is 3.'"
```

In `messageExpression`, a CEL string literal uses single quotes, and `string()` converts a number to text. If `messageExpression` fails to evaluate, the API server falls back to `message`. Keep both when you can.

You can now write a rule, scope it with a binding, preview it with `Warn`, enforce it with `Deny`, and prove the scope with dry runs. This closes the chain from the first check to the last. Authentication names the caller, authorization grants the verb, and admission judges the object.

## Common pitfalls

> [!WARNING]
> - **Creating a policy and expecting enforcement.** A policy with no binding checks nothing, and a binding with only `Warn` or `Audit` never rejects.
> - **Forgetting `UPDATE` in `operations`.** A user can then create a valid object and change it into an invalid one.
> - **Testing right after the binding is created.** Allow a few seconds, or the first request passes without the check.
> - **Missing a path that the rule does not match.** `kubectl scale` uses the `scale` subresource, not the `deployments` resource, so the rule does not see it.
> - **Using single quotes for a CEL string in YAML without quoting the line.** Wrap the whole expression in double quotes, as in the examples, so that YAML keeps the inner quotes.
