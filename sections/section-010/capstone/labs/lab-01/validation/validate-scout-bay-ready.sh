#!/usr/bin/env bash
# Check: scout-bay is Ready for its current generation, is the original object,
# and its Deployment was created by the operator (controller owner reference)
# with two available replicas.
set -uo pipefail

fail=0

hangar_json="$(kubectl -n starfleet get hangar scout-bay -o json 2>/dev/null || true)"
if [ -z "$hangar_json" ]; then
  echo "FAIL: the Hangar scout-bay does not exist in starfleet"
  exit 1
fi

ready="$(echo "$hangar_json" | jq -r '.status.conditions[]? | select(.type == "Ready") | .status')"
if [ "$ready" != "True" ]; then
  echo "FAIL: the condition Ready of scout-bay is '${ready:-missing}'"
  fail=1
fi

generation="$(echo "$hangar_json" | jq -r '.metadata.generation')"
observed="$(echo "$hangar_json" | jq -r '.status.observedGeneration // "none"')"
if [ "$generation" != "$observed" ]; then
  echo "FAIL: observedGeneration is ${observed}, metadata.generation is ${generation}"
  fail=1
fi

baseline="$(kubectl -n fleet-system get configmap lab-baseline -o jsonpath='{.data.scout-bay-uid}' 2>/dev/null || true)"
uid="$(echo "$hangar_json" | jq -r '.metadata.uid')"
if [ -n "$baseline" ] && [ "$baseline" != "$uid" ]; then
  echo "FAIL: scout-bay was deleted and created again; fix the original object"
  fail=1
fi

deployment_json="$(kubectl -n starfleet get deployment hangar-scout-bay -o json 2>/dev/null || true)"
if [ -z "$deployment_json" ]; then
  echo "FAIL: the Deployment hangar-scout-bay does not exist"
  exit 1
fi
if ! echo "$deployment_json" | jq -e --arg uid "$uid" '.metadata.ownerReferences[]? | select(.kind == "Hangar" and .uid == $uid and .controller == true)' >/dev/null 2>&1; then
  echo "FAIL: hangar-scout-bay has no controller owner reference to scout-bay"
  fail=1
fi
available="$(echo "$deployment_json" | jq -r '.status.availableReplicas // 0')"
if [ "$available" != "2" ]; then
  echo "FAIL: hangar-scout-bay has ${available} available replicas, expected 2"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-bay is Ready, owned correctly and has two available replicas"
fi
exit "$fail"
