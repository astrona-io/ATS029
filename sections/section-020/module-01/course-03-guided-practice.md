---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Grant One Namespace Permission And Verify A Denial

Role-Based Access Control adds permitted operations to an identity. You will create an observer ServiceAccount, give it a namespace-scoped Pod-reading role and verify both a permitted and a forbidden action. The administrator terminal uses impersonation to inspect effective authorization; that is not a claim that the observer can impersonate other identities.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-020/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-020-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-020-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save the identity, Role and RoleBinding as separate complete resources. The binding names both the subject and the exact role reference.

Save this as `serviceaccount-observer.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: observer
  namespace: starfleet
```

Save this as `role-pod-reader.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: starfleet
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - list
```

Save this as `rolebinding-observer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: observer-read
  namespace: starfleet
subjects:
- kind: ServiceAccount
  name: observer
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f serviceaccount-observer.yaml -f role-pod-reader.yaml -f rolebinding-observer.yaml
```

The Role scopes its rules to this namespace. A similarly named role in another namespace would not automatically grant the same permission here.

Check Pod reading, Secret reading and access in the other namespace.

```sh
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:observer
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:observer || true
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:observer || true
```

The intended results are permission to list Pods in starfleet and denial for the other checks. A denial exits nonzero, so the terminal examples allow you to continue reading evidence. No wildcard grant is needed to repair a denied unrelated action.

Remove the binding and check that the selected grant disappears.

```sh
kubectl -n starfleet delete rolebinding observer-read
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:observer || true
```

Authorization is additive. Other bindings could still grant access in a different environment, so verify effective permissions instead of assuming removal of one object revokes every possible grant.

Authentication identifies a caller, authorization decides permitted operations and admission evaluates accepted mutations under policy. This practice focuses on authorization. A positive can-i result is not proof that arbitrary admission or runtime dependencies will also succeed.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
