#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-030-01"
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

mkdir -p "$(dirname resourcequota-practice.yaml)"
cat > resourcequota-practice.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: practice-budget
  namespace: starfleet
spec:
  hard:
    requests.cpu: 100m
    requests.memory: 256Mi
CKAD_FILE_END
kubectl apply -f resourcequota-practice.yaml
kubectl -n starfleet describe resourcequota practice-budget
kubectl -n starfleet get deployment probe -o yaml
mkdir -p "$(dirname pod-over-budget.yaml)"
cat > pod-over-budget.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: Pod
metadata:
  name: over-budget
  namespace: starfleet
spec:
  containers:
  - name: work
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 200m
        memory: 32Mi
      limits:
        cpu: 200m
        memory: 64Mi
CKAD_FILE_END
if kubectl apply -f pod-over-budget.yaml; then printf "Over-budget Pod unexpectedly accepted\n" >&2; exit 1; fi
kubectl -n starfleet get pod over-budget --ignore-not-found
kubectl -n starfleet describe resourcequota practice-budget
kubectl -n starfleet delete resourcequota practice-budget
kubectl -n starfleet get pods
test -z "$(kubectl -n starfleet get pod over-budget --ignore-not-found -o name)"
printf 'ATS029/030/01: live practice checks passed\n'
