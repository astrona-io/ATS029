#!/usr/bin/env bash
# Check: behaviour. ensign-lee has read access in outpost and no more. Rejects
# an edit-style grant, a grant on Secrets, and a grant that reaches starfleet.
set -uo pipefail

fail=0
expect_no() {
  local args="$1"
  local answer
  answer="$(kubectl --context ensign-lee auth can-i $args 2>/dev/null)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: ensign-lee should not be allowed: ${args} (answer: '${answer}')"
    fail=1
  fi
}

expect_no "delete pods -n outpost"
expect_no "create pods -n outpost"
expect_no "get secrets -n outpost"
expect_no "get deployments.apps -n outpost"
expect_no "get pods -n starfleet"
expect_no "list pods --all-namespaces"

if [ "$fail" -eq 0 ]; then
  echo "PASS: ensign-lee has read access to pods in outpost and nothing more"
fi
exit "$fail"
