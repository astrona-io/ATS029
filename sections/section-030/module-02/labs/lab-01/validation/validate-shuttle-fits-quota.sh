#!/usr/bin/env bash
# Check: behaviour. shuttle keeps three replicas, all available, and every
# live pod declares the requested requests and limits. scout is untouched.
# Reading the pods catches a fix that only edited the template but never
# rolled out, and a fix that scaled shuttle down to fit.
set -uo pipefail

to_millicpu() {
  awk -v v="$1" 'BEGIN { if (v ~ /m$/) { sub(/m$/, "", v); printf "%d", v } else { printf "%d", v * 1000 } }'
}
to_mebibytes() {
  awk -v v="$1" 'BEGIN {
    if (v ~ /Gi$/) { sub(/Gi$/, "", v); printf "%d", v * 1024 }
    else if (v ~ /Mi$/) { sub(/Mi$/, "", v); printf "%d", v }
    else { printf "-1" }
  }'
}

fail=0

desired="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
available="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
if [ "$desired" != "3" ]; then
  echo "FAIL: Deployment shuttle has ${desired:-no} replicas configured, expected 3"
  fail=1
fi
if [ "${available:-0}" != "3" ]; then
  echo "FAIL: Deployment shuttle has ${available:-0} of 3 replicas available"
  fail=1
fi

live=0
while IFS='|' read -r name cpu_request memory_request cpu_limit memory_limit; do
  [ -z "$name" ] && continue
  live=$((live + 1))
  if [ -z "$cpu_request" ] || [ "$(to_millicpu "$cpu_request")" != "200" ]; then
    echo "FAIL: pod $name requests CPU '${cpu_request}', expected 200m"
    fail=1
  fi
  if [ -z "$memory_request" ] || [ "$(to_mebibytes "$memory_request")" != "128" ]; then
    echo "FAIL: pod $name requests memory '${memory_request}', expected 128Mi"
    fail=1
  fi
  if [ -z "$cpu_limit" ] || [ "$(to_millicpu "$cpu_limit")" != "400" ]; then
    echo "FAIL: pod $name limits CPU to '${cpu_limit}', expected 400m"
    fail=1
  fi
  if [ -z "$memory_limit" ] || [ "$(to_mebibytes "$memory_limit")" != "256" ]; then
    echo "FAIL: pod $name limits memory to '${memory_limit}', expected 256Mi"
    fail=1
  fi
done < <(kubectl -n starfleet get pods -l app=shuttle -o json 2>/dev/null | jq -r '
  .items[]
  | select(.metadata.deletionTimestamp == null)
  | select(.status.phase == "Running" or .status.phase == "Pending")
  | .metadata.name + "|" + (.spec.containers[0].resources.requests.cpu // "")
    + "|" + (.spec.containers[0].resources.requests.memory // "")
    + "|" + (.spec.containers[0].resources.limits.cpu // "")
    + "|" + (.spec.containers[0].resources.limits.memory // "")')

if [ "$live" -lt 3 ]; then
  echo "FAIL: only $live live shuttle pods found, expected 3"
  fail=1
fi

scout_available="$(kubectl -n starfleet get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
if [ "${scout_available:-0}" != "1" ]; then
  echo "FAIL: scout is not available"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle runs 3 replicas with the requested requests and limits"
fi
exit "$fail"
