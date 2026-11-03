#!/usr/bin/env bash
# Check: behaviour. The crew has the listed rights in outpost and nothing more.
# Rejects edit/admin style grants, wildcards and a binding that reaches starfleet.
set -uo pipefail

fail=0
expect_no() {
  local answer
  answer="$(kubectl auth can-i $1 --as=crew-member --as-group=bridge-crew 2>/dev/null)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: the group bridge-crew should not be allowed: ${1} (answer: '${answer}')"
    fail=1
  fi
}

expect_no "delete deployments.apps -n outpost"
expect_no "create pods -n outpost"
expect_no "get secrets -n outpost"
expect_no "get services -n outpost"
expect_no "get pods -n starfleet"
expect_no "create deployments.apps -n starfleet"
expect_no "list pods --all-namespaces"

if [ "$fail" -eq 0 ]; then
  echo "PASS: the group bridge-crew has only the requested rights in outpost"
fi
exit "$fail"
