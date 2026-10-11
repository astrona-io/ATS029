---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Compare Environment And Mounted ConfigMap Updates

One ConfigMap is consumed through an environment reference and a projected volume. The probe response reads the mounted file, while an exec check reads the environment. You will update the ConfigMap and observe their different timing and lifecycle contracts before restarting the workload.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-040/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-040-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-040-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save the ConfigMap and complete consuming Deployment. Both paths reference the same key under different consumption mechanisms.

Save this as `configmap-runtime-settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: runtime-settings
  namespace: starfleet
data:
  greeting: first
```

Save this as `deployment-probe-configured.yaml`:

```yaml
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
        - name: GREETING
          valueFrom:
            configMapKeyRef:
              name: runtime-settings
              key: greeting
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
          name: runtime-settings
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f configmap-runtime-settings.yaml -f deployment-probe-configured.yaml
kubectl -n starfleet rollout status deployment/probe --timeout=120s
kubectl -n starfleet exec deployment/probe -- printenv GREETING
```

The environment is captured at container start. The projected volume can update later, but propagation is not an instantaneous promise.

Change the key, then compare the existing environment and mounted file.

```sh
kubectl -n starfleet patch configmap runtime-settings -p '{"data":{"greeting":"second"}}'
kubectl -n starfleet exec deployment/probe -- printenv GREETING
kubectl -n starfleet exec deployment/probe -- cat /settings/greeting
```

Wait and inspect the file again if it still has the earlier value. A projected update requires propagation, and the application must actually reread the file to use it. The existing environment remains its startup value.

Restart the Deployment and inspect its new environment and request response.

```sh
kubectl -n starfleet rollout restart deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=120s
kubectl -n starfleet exec deployment/probe -- printenv GREETING
wait_for_success kubectl -n starfleet exec shuttle -- wget -qO- http://probe/
```

New containers should read the changed environment key. The request confirms the selected application path after restart rather than merely the existence of a ConfigMap.

Changing a ConfigMap does not by itself update every application consumption model. Environment, ordinary projection and subPath mounts have different behavior. Keep the exact mount and reread contract visible when deciding whether a configuration change needs a rollout.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
