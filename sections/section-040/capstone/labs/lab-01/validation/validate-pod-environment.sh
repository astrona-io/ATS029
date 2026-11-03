#!/usr/bin/env bash
# Check: behaviour. Every running scout pod has LOG_LEVEL=debug,
# SCOUT_LOG_LEVEL=debug and SCOUT_REGION=outpost-7, so no pod runs the old
# configuration. Rejects pods that were never restarted.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase == "Running") | .metadata.name')"
if [ -z "$pods" ]; then
  echo "FAIL: no running scout pod found"
  exit 1
fi

fail=0
for pod in $pods; do
  level="$(kubectl -n starfleet exec "$pod" -c scout -- printenv LOG_LEVEL 2>/dev/null || true)"
  prefixed_level="$(kubectl -n starfleet exec "$pod" -c scout -- printenv SCOUT_LOG_LEVEL 2>/dev/null || true)"
  region="$(kubectl -n starfleet exec "$pod" -c scout -- printenv SCOUT_REGION 2>/dev/null || true)"
  if [ "$level" != "debug" ] || [ "$prefixed_level" != "debug" ] || [ "$region" != "outpost-7" ]; then
    echo "FAIL: pod ${pod} has LOG_LEVEL='${level}', SCOUT_LOG_LEVEL='${prefixed_level}' and SCOUT_REGION='${region}', expected 'debug', 'debug' and 'outpost-7'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running scout pod has the variables from scout-config-v2"
fi
exit "$fail"
