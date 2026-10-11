#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-060-01"
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

mkdir -p "$(dirname pod-secret-consumer.yaml)"
cat > pod-secret-consumer.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: Pod
metadata:
  name: secret-consumer
  namespace: starfleet
spec:
  containers:
  - name: reader
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    env:
    - name: PRACTICE_TOKEN
      valueFrom:
        secretKeyRef:
          name: practice-token
          key: token
    volumeMounts:
    - name: secret
      mountPath: /credentials
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: practice-token
CKAD_FILE_END
kubectl -n starfleet create secret generic practice-token --from-literal=token=disposable-example
kubectl apply -f pod-secret-consumer.yaml
kubectl -n starfleet wait --for=condition=Ready pod/secret-consumer --timeout=120s
kubectl -n starfleet exec secret-consumer -- sh -c 'test -n "$PRACTICE_TOKEN"; test -s /credentials/token; wc -c < /credentials/token'
kubectl -n starfleet describe pod secret-consumer
kubectl -n starfleet get secret practice-token -o jsonpath='{.metadata.name}{" "}{.type}{"\n"}'
kubectl -n starfleet delete pod secret-consumer
kubectl -n starfleet delete secret practice-token
test -z "$(kubectl -n starfleet get secret practice-token --ignore-not-found -o name)"
printf 'ATS029/060/01: live practice checks passed\n'
