---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Consume A Mounted ConfigMap Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-040-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-040-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get deployment probe -o yaml
```

A ConfigMap volume projects keys into files. The application must read those files to use the values. This fixture reads its greeting file on each request, so the response exposes the consumed setting. The read-only mount protects the projection from application writes.


Save this as `configmap-probe-settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-settings
  namespace: starfleet
data:
  greeting: mounted
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
        - name: settings
          mountPath: /settings
          readOnly: true
      volumes:
      - name: app
        configMap:
          name: probe-code
      - name: settings
        configMap:
          name: probe-settings
```

Apply the required change:

```sh
kubectl apply -f configmap-probe-settings.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet exec shuttle -- wget -q -T 3 -O- http://probe/
kubectl -n starfleet exec deployment/probe -- cat /settings/greeting
```

Create ConfigMap `probe-settings` with `greeting: mounted`. Mount it as read-only volume `settings` at `/settings` in container `probe`. Keep two healthy replicas and the existing application code. The original client must receive `greeting=mounted` from the application, which reads the mounted file for each request.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-040-01-01`.

## Common pitfalls

> [!WARNING]
> Creating the ConfigMap alone does not make an application use it. Mount the volume at the path the process reads and verify the response. A read-only projection should stay read-only.
