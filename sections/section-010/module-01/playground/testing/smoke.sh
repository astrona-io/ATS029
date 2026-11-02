#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-010-01"
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

kubectl api-resources --api-group=training.astrona.io
kubectl explain probesetting.spec --api-version=training.astrona.io/v1
kubectl -n starfleet get deployment settings-controller
mkdir -p "$(dirname probesetting-greeting.yaml)"
cat > probesetting-greeting.yaml <<'CKAD_FILE_END'
apiVersion: training.astrona.io/v1
kind: ProbeSetting
metadata:
  name: greeting
  namespace: starfleet
spec:
  message: configured
CKAD_FILE_END
kubectl apply -f probesetting-greeting.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.ready}'=true probesetting/greeting --timeout=60s
kubectl -n starfleet get configmap settings-greeting -o yaml
kubectl -n starfleet patch probesetting greeting --type=merge -p '{"spec":{"message":"updated"}}'
kubectl -n starfleet wait --for=jsonpath='{.data.message}'=updated configmap/settings-greeting --timeout=60s
kubectl -n starfleet get probesetting greeting -o yaml
kubectl -n starfleet logs deployment/settings-controller --tail=10
test "$(kubectl -n starfleet get cm settings-greeting -o jsonpath='{.data.message}')" = updated
printf 'ATS029/010/01: live practice checks passed\n'
