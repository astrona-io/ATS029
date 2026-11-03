#!/usr/bin/env bash
# Check: drifter sets no resources itself, has 2 ready Pods, and its Pods carry
# the LimitRange defaults. Rejects the wrong fix of writing resources into
# the Deployment.
set -uo pipefail

fail=0
NS=outpost

set_in_template="$(kubectl -n $NS get deployment drifter -o json 2>/dev/null | jq -r '.spec.template.spec.containers[0].resources | if . == null or . == {} then "" else "set" end')"
if [ "$set_in_template" = "set" ]; then
  echo "FAIL: the drifter Deployment sets resources itself; they must come from the LimitRange"
  fail=1
fi

if ! kubectl -n $NS rollout status deployment/drifter --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the drifter Deployment is not fully rolled out"
  fail=1
fi

ready="$(kubectl -n $NS get deployment drifter -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
if [ "${ready:-0}" -ne 2 ]; then
  echo "FAIL: drifter has ${ready:-0} ready Pods, expected 2"
  fail=1
fi

bad="$(kubectl -n $NS get pods -l app=drifter -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.spec.containers[0].resources.requests.cpu != "100m" or .spec.containers[0].resources.limits.cpu != "200m" or .spec.containers[0].resources.limits.memory != "128Mi") | .metadata.name')"
if [ -n "$bad" ]; then
  echo "FAIL: these drifter Pods do not carry the default values: $(echo "$bad" | tr '\n' ' ')"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: drifter runs with the LimitRange defaults"
fi
exit "$fail"
