#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-040-01"
practice_directory="$(mktemp -d)"
cleanup() {
  if [[ -n "${PORT_FORWARD_PID:-}" ]]; then kill "$PORT_FORWARD_PID" 2>/dev/null || true; fi
  rm -rf "$practice_directory"
}
trap cleanup EXIT
cd "$practice_directory"
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}

mkdir -p "$(dirname configmap-runtime-settings.yaml)"
cat > configmap-runtime-settings.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: ConfigMap
metadata:
  name: runtime-settings
  namespace: starfleet
data:
  greeting: first
CKAD_FILE_END
mkdir -p "$(dirname deployment-probe-configured.yaml)"
cat > deployment-probe-configured.yaml <<'CKAD_FILE_END'
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
CKAD_FILE_END
kubectl apply -f configmap-runtime-settings.yaml -f deployment-probe-configured.yaml
kubectl -n starfleet rollout status deployment/probe --timeout=120s
kubectl -n starfleet exec deployment/probe -- printenv GREETING
kubectl -n starfleet patch configmap runtime-settings -p '{"data":{"greeting":"second"}}'
kubectl -n starfleet exec deployment/probe -- printenv GREETING
kubectl -n starfleet exec deployment/probe -- cat /settings/greeting
kubectl -n starfleet rollout restart deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=120s
kubectl -n starfleet exec deployment/probe -- printenv GREETING
wait_for_success kubectl -n starfleet exec shuttle -- wget -qO- http://probe/
test "$(kubectl -n starfleet exec deployment/probe -- printenv GREETING)" = second
printf 'ATS029/040/01: live practice checks passed\n'
