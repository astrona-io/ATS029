---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Grant Namespace Pod Read Access Solution

Use this lab's private kubeconfig. A kubeconfig contains the cluster address and credentials used by kubectl, the Kubernetes command-line tool. The lab has a separate kind cluster from the module playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-020-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-020-01-01" || exit 1
```

Keep this connection selected for every command below.

## Diagnose The Starting State

The `starfleet` and `outpost` namespaces and `starfleet/shuttle` ServiceAccount exist. A ServiceAccount identifies a workload when it calls the Kubernetes application programming interface (API). It has no application-specific Pod read grant.

Inspect the relevant objects:

```sh
kubectl -n starfleet get serviceaccount shuttle
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:shuttle
```

Role-Based Access Control (RBAC) grants resource actions through roles and bindings. The Role defines the allowed actions. The RoleBinding connects the ServiceAccount to that Role within `starfleet`. Grants combine, so check effective denied actions as well as the new allowed actions. `kubectl auth can-i` returns a nonzero exit status for a denied action; that is expected for the denial checks.

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
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: shuttle-pod-reader
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: shuttle
  namespace: starfleet
```

Apply it:

```sh
kubectl apply -f role-pod-reader.yaml
```

## Verify The Result

Observe the actual result with these bounded checks. No example transcript is provided as evidence of a completed run.

```sh
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:shuttle
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:shuttle
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:shuttle
```

Create Role `pod-reader` and RoleBinding `shuttle-pod-reader` in `starfleet`. Grant ServiceAccount `shuttle` in `starfleet` exactly `get`, `list` and `watch` on core Pods. The binding must reference that Role and only that ServiceAccount. Do not add a ClusterRoleBinding or any other grant. Pod creation and deletion, Secret reads, Pod reads in `outpost` and node reads must remain denied.

After recording your result, remove this lab with `astrona destroy ats-029-lab-020-01-01`.

## Common pitfalls

> [!WARNING]
> Verify the lab context before making changes. A matching field alone does not prove the required behavior. Preserve the objects and access limits named in the task.
