#!/usr/bin/env bash
# Check: the ResourceQuota starfleet-budget exists in starfleet with exactly the
# hard values from the task. Quantities are compared after normalising units,
# so "1" and "1000m" are equal. A raised quota fails here.
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

if ! kubectl -n starfleet get resourcequota starfleet-budget >/dev/null 2>&1; then
  echo "FAIL: ResourceQuota starfleet-budget does not exist in starfleet"
  exit 1
fi

hard() {
  kubectl -n starfleet get resourcequota starfleet-budget -o json 2>/dev/null | jq -r --arg key "$1" '.spec.hard[$key] // ""'
}

check_cpu() {
  local key="$1" expected="$2" actual
  actual="$(hard "$key")"
  if [ -z "$actual" ] || [ "$(to_millicpu "$actual")" != "$expected" ]; then
    echo "FAIL: $key is '${actual}', expected ${expected}m"
    fail=1
  fi
}
check_memory() {
  local key="$1" expected="$2" actual
  actual="$(hard "$key")"
  if [ -z "$actual" ] || [ "$(to_mebibytes "$actual")" != "$expected" ]; then
    echo "FAIL: $key is '${actual}', expected ${expected}Mi"
    fail=1
  fi
}
check_count() {
  local key="$1" expected="$2" actual
  actual="$(hard "$key")"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $key is '${actual}', expected ${expected}"
    fail=1
  fi
}

check_cpu requests.cpu 1000
check_cpu limits.cpu 2000
check_memory requests.memory 1024
check_memory limits.memory 2048
check_count pods 6

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet-budget has the requested hard values"
fi
exit "$fail"
