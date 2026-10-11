---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Use A Workload ServiceAccount For A Real API Request

A ServiceAccount supplies workload identity, while RBAC separately grants operations. You will assign the observer identity to the probe workload and make a real HTTPS API request using its projected token and cluster certificate authority. The token is read inside the container and never printed.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-070/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-070-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-070-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save the ServiceAccount, narrow Role and RoleBinding, then assign the workload identity.

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
kubectl -n starfleet set serviceaccount deployment/probe observer
kubectl -n starfleet rollout status deployment/probe --timeout=120s
```

A template identity change creates new Pods. The binding permits Pod reading in this namespace rather than unrestricted cluster administration.

Inspect the selected identity and make an authenticated API request from the application container.

```sh
kubectl -n starfleet get pods -l app=probe -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.serviceAccountName}{"\n"}{end}'
kubectl -n starfleet exec deployment/probe -- python -c 'from pathlib import Path; import ssl,urllib.request,json; root=Path('"'"'/var/run/secrets/kubernetes.io/serviceaccount'"'"'); request=urllib.request.Request('"'"'https://kubernetes.default.svc/api/v1/namespaces/starfleet/pods'"'"',headers={'"'"'Authorization'"'"':'"'"'Bearer '"'"'+(root/'"'"'token'"'"').read_text()}); context=ssl.create_default_context(cafile=str(root/'"'"'ca.crt'"'"')); response=json.load(urllib.request.urlopen(request,context=context)); print('"'"'visible-pods='"'"'+str(len(response['"'"'items'"'"'])))'
```

The request uses the service-account token and validates the API certificate with the mounted CA. A returned item count demonstrates that selected read operation, not permission for every other resource.

Check an ungranted operation using administrator-side impersonation.

```sh
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:observer || true
kubectl -n starfleet get role pod-reader -o yaml
```

The intended Secret read is denied. Impersonation is a diagnostic ability of the administrator terminal, not an ability supplied to the observer by this Role.

A projected token can expire and rotate under its bound workload contract. Applications should read and use credentials appropriately rather than copy them into public data. If a workload never calls the API, disabling unnecessary automounting can reduce exposure without changing its declared ServiceAccount name.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
