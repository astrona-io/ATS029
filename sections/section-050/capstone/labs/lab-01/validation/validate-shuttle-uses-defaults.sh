#!/usr/bin/env bash
# Check: the LimitRange starfleet-defaults has the required values, the shuttle
# Deployment sets no resources itself, and its Pod carries the defaults.
set -uo pipefail

fail=0
NS=starfleet

if ! kubectl -n $NS get limitrange starfleet-defaults >/dev/null 2>&1; then
  echo "FAIL: the LimitRange starfleet-defaults does not exist"
  exit 1
fi

rule="$(kubectl -n $NS get limitrange starfleet-defaults -o json | jq -c '.spec.limits[] | select(.type=="Container")' | head -n 1)"
expect() {
  local path="$1" expected="$2" actual
  actual="$(echo "$rule" | jq -r "$path // empty")"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: LimitRange $path is '${actual}', expected '${expected}'"
    fail=1
  fi
}
expect '.default.cpu' 100m
expect '.default.memory' 64Mi
expect '.defaultRequest.cpu' 50m
expect '.defaultRequest.memory' 32Mi
expect '.max.cpu' 500m
expect '.max.memory' 512Mi

set_in_template="$(kubectl -n $NS get deployment shuttle -o json 2>/dev/null | jq -r '.spec.template.spec.containers[0].resources | if . == null or . == {} then "" else "set" end')"
if [ "$set_in_template" = "set" ]; then
  echo "FAIL: the shuttle Deployment sets resources itself; they must come from the LimitRange"
  fail=1
fi

if ! kubectl -n $NS rollout status deployment/shuttle --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment is not rolled out"
  fail=1
fi
bad="$(kubectl -n $NS get pods -l app=shuttle -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.spec.containers[0].resources.requests.cpu != "50m" or .spec.containers[0].resources.limits.cpu != "100m" or .spec.containers[0].resources.limits.memory != "64Mi") | .metadata.name')"
active="$(kubectl -n $NS get pods -l app=shuttle -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running")] | length')"
if [ -n "$bad" ] || [ "${active:-0}" -lt 1 ]; then
  echo "FAIL: the shuttle Pod is not Running with the LimitRange defaults"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle runs with the starfleet-defaults values"
fi
exit "$fail"
