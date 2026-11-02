---
draft: true
exam_objectives:
- Define resource requirements
---
# Declare Resources For Every Container Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-050-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-050-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get deployment probe -o yaml
```

The scheduler accounts for resource requests from every ordinary container. Limits constrain each container separately. Adding a companion container without declarations changes the Pod budget assumptions. Keep both containers within the stated requests and limits and verify the complete Pod becomes ready.


Save this as `deployment-probe.yaml`:

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
            cpu: 20m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: app
          mountPath: /app
          readOnly: true
      - name: observer
        image: docker.io/library/busybox:1.37.0
        command:
        - sh
        - -c
        - sleep 3600
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
      volumes:
      - name: app
        configMap:
          name: probe-code
```

Apply the required change:

```sh
kubectl apply -f deployment-probe.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet exec shuttle -- wget -q -T 3 -O- http://probe/
```

Keep two probe replicas and add ordinary container `observer` using BusyBox 1.37.0 with a sleeping process. Declare probe requests of 20m CPU and 32Mi memory with limits of 100m and 128Mi. Declare observer requests of 10m and 16Mi with limits of 50m and 64Mi. Both containers must be ready in both Pods. Preserve the original Service response.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-050-01-01`.

## Common pitfalls

> [!WARNING]
> Declare requests and limits on both ordinary containers. A declaration on one container does not cover its companion. Keep the original readiness probe and application capacity.
