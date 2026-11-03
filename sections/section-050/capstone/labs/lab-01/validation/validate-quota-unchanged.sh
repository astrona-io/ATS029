#!/usr/bin/env bash
# Check: starfleet-quota keeps its original values (not raised, not deleted)
# and the namespace usage is inside it.
set -uo pipefail

fail=0
NS=starfleet

if ! kubectl -n $NS get resourcequota starfleet-quota >/dev/null 2>&1; then
  echo "FAIL: the ResourceQuota starfleet-quota was deleted"
  exit 1
fi

hard="$(kubectl -n $NS get resourcequota starfleet-quota -o json | jq -c '.spec.hard')"
expect() {
  local key="$1" expected="$2" actual
  actual="$(echo "$hard" | jq -r --arg k "$key" '.[$k] // empty')"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: spec.hard[$key] is '${actual}', expected '${expected}'"
    fail=1
  fi
}
expect pods 8
expect requests.cpu 1
expect requests.memory 1Gi
expect limits.cpu 2
expect limits.memory 2Gi

extra="$(echo "$hard" | jq -r 'keys | length')"
if [ "$extra" -ne 5 ]; then
  echo "FAIL: the quota has ${extra} entries, expected the original 5"
  fail=1
fi

used_cpu="$(kubectl -n $NS get resourcequota starfleet-quota -o jsonpath='{.status.used.requests\.cpu}' 2>/dev/null || true)"
case "$used_cpu" in
  *m) used_millis="${used_cpu%m}" ;;
  '') used_millis="" ;;
  *) used_millis=$(( ${used_cpu%%.*} * 1000 )) ;;
esac
if [ -z "$used_millis" ] || [ "$used_millis" -gt 1000 ] || [ "$used_millis" -lt 300 ]; then
  echo "FAIL: the quota reports ${used_cpu:-no} used CPU requests; all three workloads must be running inside the quota"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet-quota is unchanged and the namespace is inside it"
fi
exit "$fail"
