#!/usr/bin/env bash
# Check: the LimitRange outpost-limits exists with a Container entry that has
# exactly the values from the task. Units are normalised, so "1" and "1000m"
# are equal. A raised maximum or a missing ratio fails here.
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

if ! kubectl -n outpost get limitrange outpost-limits >/dev/null 2>&1; then
  echo "FAIL: LimitRange outpost-limits does not exist in outpost"
  exit 1
fi

fail=0
limitrange_json="$(kubectl -n outpost get limitrange outpost-limits -o json 2>/dev/null)"

field() {
  echo "$limitrange_json" | jq -r --arg section "$1" --arg resource "$2" \
    '[.spec.limits[] | select(.type == "Container")][0][$section][$resource] // ""'
}

check_cpu() {
  local section="$1" expected="$2" actual
  actual="$(field "$section" cpu)"
  if [ -z "$actual" ] || [ "$(to_millicpu "$actual")" != "$expected" ]; then
    echo "FAIL: Container $section cpu is '${actual}', expected ${expected}m"
    fail=1
  fi
}
check_memory() {
  local section="$1" expected="$2" actual
  actual="$(field "$section" memory)"
  if [ -z "$actual" ] || [ "$(to_mebibytes "$actual")" != "$expected" ]; then
    echo "FAIL: Container $section memory is '${actual}', expected ${expected}Mi"
    fail=1
  fi
}

check_cpu default 200
check_memory default 256
check_cpu defaultRequest 100
check_memory defaultRequest 128
check_cpu min 50
check_memory min 64
check_cpu max 500
check_memory max 512

ratio="$(field maxLimitRequestRatio cpu)"
if [ "$ratio" != "4" ]; then
  echo "FAIL: Container maxLimitRequestRatio cpu is '${ratio}', expected 4"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: outpost-limits has the requested Container values"
fi
exit "$fail"
