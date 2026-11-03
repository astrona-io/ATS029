#!/usr/bin/env bash
# Check: every scout Pod is Guaranteed, and the init container and sidecar
# have equal requests and limits. A change to the main container alone fails.
set -uo pipefail

fail=0
NS=starfleet

if ! kubectl -n $NS rollout status deployment/scout --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the scout Deployment did not finish rolling out"
  fail=1
fi

pods="$(kubectl -n $NS get pods -l app=scout -o json 2>/dev/null)"
active="$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp==null)] | length')"
if [ "${active:-0}" -lt 1 ]; then
  echo "FAIL: no scout Pod exists"
  fail=1
fi

not_guaranteed="$(echo "$pods" | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.status.qosClass != "Guaranteed") | .metadata.name')"
if [ -n "$not_guaranteed" ]; then
  echo "FAIL: these scout Pods are not Guaranteed: $(echo "$not_guaranteed" | tr '\n' ' ')"
  fail=1
fi

# Every container in the Deployment template, init containers included.
unequal="$(kubectl -n $NS get deployment scout -o json | jq -r '
  .spec.template.spec
  | [(.initContainers // [])[], .containers[]]
  | .[]
  | select(
      (.resources.limits.cpu == null) or (.resources.limits.memory == null)
      or (.resources.requests.cpu != .resources.limits.cpu)
      or (.resources.requests.memory != .resources.limits.memory))
  | .name')"
if [ -n "$unequal" ]; then
  echo "FAIL: these containers need equal CPU and memory requests and limits: $(echo "$unequal" | tr '\n' ' ')"
  fail=1
fi

ready="$(kubectl -n $NS get deployment scout -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
if [ "${ready:-0}" -lt 1 ]; then
  echo "FAIL: scout has no ready replica"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout is Guaranteed and ready"
fi
exit "$fail"
