#!/usr/bin/env bash
# Check: every container (init containers and sidecars included) of the three
# Deployments still has CPU and memory requests. Rejects the wrong fix of
# deleting the resources field.
set -uo pipefail

fail=0
NS=starfleet

for name in shuttle scout probe; do
  missing="$(kubectl -n $NS get deployment "$name" -o json 2>/dev/null | jq -r '
    .spec.template.spec
    | [(.initContainers // [])[], .containers[]]
    | .[]
    | select((.resources.requests.cpu == null) or (.resources.requests.memory == null))
    | .name')"
  if [ -n "$missing" ]; then
    echo "FAIL: $name has containers without CPU and memory requests: $(echo "$missing" | tr '\n' ' ')"
    fail=1
  fi
done

classes="$(kubectl -n $NS get pods -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.status.qosClass=="BestEffort") | .metadata.name')"
if [ -n "$classes" ]; then
  echo "FAIL: these Pods are BestEffort: $(echo "$classes" | tr '\n' ' ')"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: all containers keep CPU and memory requests"
fi
exit "$fail"
