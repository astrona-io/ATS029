---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Use A Workload Identity For An API Request Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-070-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-070-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get deployment probe -o yaml
```

A ServiceAccount identifies the workload to the API server. The projected token authenticates the request, while RBAC controls the permitted action. Using the mounted certificate authority verifies the API server identity. A host-side authorization check alone does not prove that the workload can authenticate.


Save this as `serviceaccount-observer.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: observer
  namespace: starfleet
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: observer-reader
  namespace: starfleet
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: observer-read
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: observer-reader
subjects:
- kind: ServiceAccount
  name: observer
  namespace: starfleet
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe
  namespace: starfleet
spec:
  replicas: 2
  selector:
    matchLabels:
      app: probe
      release: probe
  template:
    metadata:
      labels:
        app: probe
        release: probe
    spec:
      containers:
      - name: probe
        image: docker.io/library/python:3.13-alpine
        command:
        - python
        - /app/server.py
        env:
        - name: VERSION
          value: v1
        ports:
        - name: http
          containerPort: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          periodSeconds: 2
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
          limits:
            memory: 128Mi
        volumeMounts:
        - name: app
          mountPath: /app
          readOnly: true
      volumes:
      - name: app
        configMap:
          name: probe-code
      serviceAccountName: observer
```

Apply the required change:

```sh
kubectl apply -f serviceaccount-observer.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet exec deployment/probe -- python -c 'from pathlib import Path; import ssl,urllib.request,json; root=Path('"'"'/var/run/secrets/kubernetes.io/serviceaccount'"'"'); request=urllib.request.Request('"'"'https://kubernetes.default.svc/api/v1/namespaces/starfleet/pods'"'"',headers={'"'"'Authorization'"'"':'"'"'Bearer '"'"'+(root/'"'"'token'"'"').read_text()}); context=ssl.create_default_context(cafile=str(root/'"'"'ca.crt'"'"')); result=json.load(urllib.request.urlopen(request,context=context,timeout=5)); print(result['"'"'kind'"'"'])'
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:observer
kubectl auth can-i create pods -n starfleet --as=system:serviceaccount:starfleet:observer
```

Create ServiceAccount `observer`, Role `observer-reader` granting exactly get and list on core Pods, and RoleBinding `observer-read` for that identity in `starfleet`. Run both probe replicas as that ServiceAccount. A request from the application container using its mounted token and certificate authority must read the namespace Pod list. Secret reads and Pod creation must remain denied.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-070-01-01`.

## Common pitfalls

> [!WARNING]
> Run the workload as the intended ServiceAccount and verify the request inside its container. A host-side authorization check does not prove workload authentication. Keep certificate verification enabled.
