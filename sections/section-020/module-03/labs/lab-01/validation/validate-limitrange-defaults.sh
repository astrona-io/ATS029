#!/usr/bin/env bash
# Check: behaviour. A pod without resources in outpost receives the default
# requests and limits from the LimitRange (server-side dry run, nothing is
# stored). The same pod in starfleet receives nothing, so the LimitRange must
# not be in the wrong namespace.
set -uo pipefail

read_resource() {
  # $1 namespace, $2 jsonpath
  kubectl -n "$1" run limit-check --image=busybox:1.37.0 --restart=Never \
    --dry-run=server -o jsonpath="$2" 2>/dev/null
}

fail=0
check_value() {
  local label="$1" expected="$2" path="$3" actual
  actual="$(read_resource outpost "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: ${label} in outpost is '${actual}', expected '${expected}'"
    fail=1
  fi
}

check_value "request cpu" "50m" '{.spec.containers[0].resources.requests.cpu}'
check_value "request memory" "32Mi" '{.spec.containers[0].resources.requests.memory}'
check_value "limit cpu" "200m" '{.spec.containers[0].resources.limits.cpu}'
check_value "limit memory" "64Mi" '{.spec.containers[0].resources.limits.memory}'

other="$(read_resource starfleet '{.spec.containers[0].resources.limits.cpu}')"
if [ -n "$other" ]; then
  echo "FAIL: a pod in starfleet receives the limit '${other}', but only outpost should have defaults"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: containers in outpost receive the default requests and limits"
fi
exit "$fail"
