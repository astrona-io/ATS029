#!/usr/bin/env bash
# Check: no Pod is BestEffort, images and replica counts are unchanged, and
# all three Deployments are available.
set -uo pipefail

fail=0
NS=starfleet

besteffort="$(kubectl -n $NS get pods -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | select(.status.qosClass=="BestEffort") | .metadata.name')"
if [ -n "$besteffort" ]; then
  echo "FAIL: these Pods are BestEffort: $(echo "$besteffort" | tr '\n' ' ')"
  fail=1
fi

for name in bridge scout shuttle; do
  image="$(kubectl -n $NS get deployment "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  replicas="$(kubectl -n $NS get deployment "$name" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
  available="$(kubectl -n $NS get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "$image" != "busybox:1.37.0" ]; then
    echo "FAIL: $name image is '${image}', expected busybox:1.37.0"
    fail=1
  fi
  if [ "$replicas" != "1" ]; then
    echo "FAIL: $name has ${replicas:-no} replicas, expected 1"
    fail=1
  fi
  if [ "${available:-0}" -lt 1 ]; then
    echo "FAIL: $name has no available replica"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no BestEffort Pods, images and replicas unchanged, all Deployments available"
fi
exit "$fail"
