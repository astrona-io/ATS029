#!/usr/bin/env bash
# Check: scout Pods exist, are Ready and Guaranteed; every container (init
# container and sidecar included) has equal requests and limits; the sidecar stays.
set -uo pipefail

fail=0
NS=starfleet

if ! kubectl -n $NS rollout status deployment/scout --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the scout Deployment did not finish rolling out (no admitted Pod?)"
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

sidecar="$(kubectl -n $NS get deployment scout -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="log-shipper")].restartPolicy}' 2>/dev/null || true)"
if [ "$sidecar" != "Always" ]; then
  echo "FAIL: the log-shipper sidecar must stay in the scout Pod (restartPolicy Always)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout is admitted, Ready and Guaranteed"
fi
exit "$fail"
