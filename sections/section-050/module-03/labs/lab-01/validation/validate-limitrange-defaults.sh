#!/usr/bin/env bash
# Check: the LimitRange outpost-defaults has the required Container rule.
set -uo pipefail

fail=0
NS=outpost

if ! kubectl -n $NS get limitrange outpost-defaults >/dev/null 2>&1; then
  echo "FAIL: the LimitRange outpost-defaults does not exist in $NS"
  exit 1
fi

rule="$(kubectl -n $NS get limitrange outpost-defaults -o json | jq -c '.spec.limits[] | select(.type=="Container")' | head -n 1)"
if [ -z "$rule" ]; then
  echo "FAIL: outpost-defaults has no rule of type Container"
  exit 1
fi

expect() {
  local path="$1" expected="$2" actual
  actual="$(echo "$rule" | jq -r "$path // empty")"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $path is '${actual}', expected '${expected}'"
    fail=1
  fi
}

expect '.default.cpu' 200m
expect '.default.memory' 128Mi
expect '.default["ephemeral-storage"]' 200Mi
expect '.defaultRequest.cpu' 100m
expect '.defaultRequest.memory' 64Mi
expect '.defaultRequest["ephemeral-storage"]' 50Mi
expect '.max.cpu' 500m
expect '.max.memory' 256Mi

if [ "$fail" -eq 0 ]; then
  echo "PASS: outpost-defaults has the required defaults and maximums"
fi
exit "$fail"
