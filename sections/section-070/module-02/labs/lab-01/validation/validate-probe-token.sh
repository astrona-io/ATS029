#!/usr/bin/env bash
# Check: behaviour. probe pods still mount an API token, so the learner did not
# switch the mount off everywhere (on the default account or in the template).
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null | jq -c '[.items[] | select(.metadata.deletionTimestamp == null)]')"
count="$(echo "$pods" | jq 'length')"
if [ -z "$count" ] || [ "$count" -lt 1 ]; then
  echo "FAIL: no running probe pods found"
  exit 1
fi

fail=0
for index in $(seq 0 $((count - 1))); do
  name="$(echo "$pods" | jq -r ".[$index].metadata.name")"
  token_volumes="$(echo "$pods" | jq -r ".[$index].spec.volumes // [] | map(select(.name | startswith(\"kube-api-access\"))) | length")"
  if [ "$token_volumes" = "0" ]; then
    echo "FAIL: pod $name has no token volume, but probe must still mount an API token"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe pods still mount an API token"
fi
exit "$fail"
