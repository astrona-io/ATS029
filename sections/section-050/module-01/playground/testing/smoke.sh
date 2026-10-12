#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-050-01"
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

mkdir -p "$(dirname pod-resource-pair.yaml)"
cat > pod-resource-pair.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: Pod
metadata:
  name: resource-pair
  namespace: starfleet
spec:
  containers:
  - name: main
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 50m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 64Mi
  - name: support
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 20m
        memory: 16Mi
      limits:
        cpu: 50m
        memory: 32Mi
CKAD_FILE_END
kubectl apply -f pod-resource-pair.yaml
kubectl -n starfleet wait --for=condition=Ready pod/resource-pair --timeout=120s
kubectl -n starfleet get pod resource-pair -o jsonpath='{range .spec.containers[*]}{.name}{" "}{.resources}{"\n"}{end}'
kubectl -n starfleet describe pod resource-pair
kubectl -n starfleet exec resource-pair -c main -- ps
kubectl -n starfleet get pod resource-pair -o wide
kubectl get nodes
test "$(kubectl -n starfleet get pod resource-pair -o jsonpath='{.spec.containers[1].resources.requests.cpu}')" = 20m
printf 'ATS029/050/01: live practice checks passed\n'
