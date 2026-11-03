#!/usr/bin/env bash
# Check: the Deployment finished its rollout, every pod is ready and runs the
# new template, and LOG_LEVEL inside every pod is the ConfigMap value (debug),
# not the old fixed value (warn).
set -uo pipefail

if ! kubectl -n starfleet rollout status deployment/probe --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the rollout of deployment/probe is not complete"
  exit 1
fi

json="$(kubectl -n starfleet get deployment probe -o json)"
desired="$(echo "$json" | jq -r '.spec.replicas')"
available="$(echo "$json" | jq -r '.status.availableReplicas // 0')"
if [ "$desired" != "2" ] || [ "$available" != "2" ]; then
  echo "FAIL: expected 2 desired and 2 available replicas, found ${desired} desired and ${available} available"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=probe -o json \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | .metadata.name')"
fail=0
count=0
for pod in $pods; do
  count=$((count + 1))
  level="$(kubectl -n starfleet exec "$pod" -c probe -- printenv LOG_LEVEL 2>/dev/null || true)"
  if [ "$level" != "debug" ]; then
    echo "FAIL: pod ${pod} has LOG_LEVEL='${level}', expected 'debug'"
    fail=1
  fi
done
if [ "$count" -ne 2 ]; then
  echo "FAIL: expected 2 probe pods, found ${count}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: both probe pods run the new configuration"
fi
exit "$fail"
