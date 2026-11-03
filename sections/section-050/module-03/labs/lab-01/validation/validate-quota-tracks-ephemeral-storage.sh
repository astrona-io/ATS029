#!/usr/bin/env bash
# Check: outpost-quota keeps its original values and adds the two ephemeral
# storage caps. Rejects deleting the quota or raising the old values.
set -uo pipefail

fail=0
NS=outpost

if ! kubectl -n $NS get resourcequota outpost-quota >/dev/null 2>&1; then
  echo "FAIL: the ResourceQuota outpost-quota was deleted"
  exit 1
fi

hard="$(kubectl -n $NS get resourcequota outpost-quota -o json | jq -c '.spec.hard')"
expect() {
  local key="$1" expected="$2" actual
  actual="$(echo "$hard" | jq -r --arg k "$key" '.[$k] // empty')"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: spec.hard[$key] is '${actual}', expected '${expected}'"
    fail=1
  fi
}
expect pods 6
expect requests.cpu 1
expect requests.memory 1Gi
expect limits.cpu 2
expect limits.memory 2Gi
expect requests.ephemeral-storage 1Gi
expect limits.ephemeral-storage 2Gi

if [ "$fail" -eq 0 ]; then
  used=""
  for _ in $(seq 1 15); do
    used="$(kubectl -n $NS get resourcequota outpost-quota -o jsonpath='{.status.used.requests\.ephemeral-storage}' 2>/dev/null || true)"
    if [ -n "$used" ]; then break; fi
    sleep 2
  done
  if [ -z "$used" ]; then
    echo "FAIL: the quota does not report any used ephemeral storage yet"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: outpost-quota caps ephemeral storage and keeps its other values"
fi
exit "$fail"
