#!/usr/bin/env bash
# Check: scout-bay is Ready, its status describes the current generation, and
# it is the same object that existed at the start (not deleted and recreated).
set -uo pipefail

fail=0

hangar_json="$(kubectl -n starfleet get hangar scout-bay -o json 2>/dev/null || true)"
if [ -z "$hangar_json" ]; then
  echo "FAIL: the Hangar scout-bay does not exist in starfleet"
  exit 1
fi

ready="$(echo "$hangar_json" | jq -r '.status.conditions[]? | select(.type == "Ready") | .status')"
if [ "$ready" != "True" ]; then
  reason="$(echo "$hangar_json" | jq -r '.status.conditions[]? | select(.type == "Ready") | .reason // ""')"
  echo "FAIL: the condition Ready of scout-bay is '${ready:-missing}' (reason: ${reason:-none})"
  fail=1
fi

generation="$(echo "$hangar_json" | jq -r '.metadata.generation')"
observed="$(echo "$hangar_json" | jq -r '.status.observedGeneration // "none"')"
if [ "$generation" != "$observed" ]; then
  echo "FAIL: observedGeneration is ${observed}, metadata.generation is ${generation}"
  fail=1
fi

replicas="$(echo "$hangar_json" | jq -r '.spec.replicas')"
if [ "$replicas" != "2" ]; then
  echo "FAIL: scout-bay has spec.replicas ${replicas}, expected 2"
  fail=1
fi

baseline="$(kubectl -n fleet-system get configmap lab-baseline -o jsonpath='{.data.scout-bay-uid}' 2>/dev/null || true)"
current="$(echo "$hangar_json" | jq -r '.metadata.uid')"
if [ -n "$baseline" ] && [ "$baseline" != "$current" ]; then
  echo "FAIL: scout-bay was deleted and created again; fix the original object"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-bay is Ready for its current generation"
fi
exit "$fail"
