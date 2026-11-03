#!/usr/bin/env bash
# Check: every active Pod in outpost has ephemeral storage requests and limits
# on every container, and at least 3 Pods exist (2 drifter and 1 beacon).
set -uo pipefail

fail=0
NS=outpost

pods="$(kubectl -n $NS get pods -o json 2>/dev/null)"
count="$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running")] | length')"
if [ "${count:-0}" -lt 3 ]; then
  echo "FAIL: expected at least 3 running Pods in $NS, found ${count:-0}"
  fail=1
fi

missing="$(echo "$pods" | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running") | select(any(.spec.containers[]; (.resources.requests["ephemeral-storage"] == null) or (.resources.limits["ephemeral-storage"] == null))) | .metadata.name')"
if [ -n "$missing" ]; then
  echo "FAIL: these Pods have no ephemeral storage request or limit: $(echo "$missing" | tr '\n' ' ')"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running Pod in $NS states ephemeral storage requests and limits"
fi
exit "$fail"
