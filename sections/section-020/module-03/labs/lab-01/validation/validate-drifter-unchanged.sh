#!/usr/bin/env bash
# Check: the drifter and scout Deployments still exist with one available replica.
set -uo pipefail

fail=0
for target in "outpost drifter" "starfleet scout"; do
  set -- $target
  replicas="$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  available="$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ "$replicas" != "1" ]; then
    echo "FAIL: deployment ${2} in ${1} has replicas '${replicas}', expected 1"
    fail=1
  elif [ "${available:-0}" -lt 1 ]; then
    echo "FAIL: deployment ${2} in ${1} has no available replica"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: drifter and scout are unchanged and available"
fi
exit "$fail"
