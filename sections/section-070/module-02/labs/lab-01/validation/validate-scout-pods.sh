#!/usr/bin/env bash
# Check: every running scout pod uses the scout account and has no token
# volume. Reading the pods catches a Deployment that was not rolled, and a
# token switched off only in the pod template (the account value is checked
# by a separate script).
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null | jq -c '[.items[] | select(.metadata.deletionTimestamp == null)]')"
count="$(echo "$pods" | jq 'length')"
if [ -z "$count" ] || [ "$count" -lt 1 ]; then
  echo "FAIL: no running scout pods found"
  exit 1
fi

fail=0
for index in $(seq 0 $((count - 1))); do
  name="$(echo "$pods" | jq -r ".[$index].metadata.name")"
  account="$(echo "$pods" | jq -r ".[$index].spec.serviceAccountName")"
  token_volumes="$(echo "$pods" | jq -r ".[$index].spec.volumes // [] | map(select(.name | startswith(\"kube-api-access\"))) | length")"
  if [ "$account" != "scout" ]; then
    echo "FAIL: pod $name uses account '${account}', expected scout"
    fail=1
  fi
  if [ "$token_volumes" != "0" ]; then
    echo "FAIL: pod $name still has a token volume (kube-api-access)"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout pods use the scout account and have no token volume"
fi
exit "$fail"
