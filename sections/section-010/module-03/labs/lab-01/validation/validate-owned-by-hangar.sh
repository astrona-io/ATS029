#!/usr/bin/env bash
# Check: the Deployment hangar-scout-bay has a controller owner reference to
# the live scout-bay, two available replicas, and the operator still runs.
# Rejects a Deployment created by hand.
set -uo pipefail

fail=0

hangar_uid="$(kubectl -n starfleet get hangar scout-bay -o jsonpath='{.metadata.uid}' 2>/dev/null || true)"
deployment_json="$(kubectl -n starfleet get deployment hangar-scout-bay -o json 2>/dev/null || true)"
if [ -z "$hangar_uid" ] || [ -z "$deployment_json" ]; then
  echo "FAIL: the Hangar scout-bay or the Deployment hangar-scout-bay is missing"
  exit 1
fi

if ! echo "$deployment_json" | jq -e --arg uid "$hangar_uid" '.metadata.ownerReferences[]? | select(.kind == "Hangar" and .name == "scout-bay" and .uid == $uid and .controller == true)' >/dev/null 2>&1; then
  echo "FAIL: hangar-scout-bay has no controller owner reference to scout-bay"
  fail=1
fi

available="$(echo "$deployment_json" | jq -r '.status.availableReplicas // 0')"
if [ "$available" != "2" ]; then
  echo "FAIL: hangar-scout-bay has ${available} available replicas, expected 2"
  fail=1
fi

operator_ready="$(kubectl -n fleet-system get deployment hangar-operator -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
operator_account="$(kubectl -n fleet-system get deployment hangar-operator -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || true)"
if [ "${operator_ready:-0}" -lt 1 ] || [ "$operator_account" != "hangar-operator" ]; then
  echo "FAIL: the operator Deployment is not running with the service account hangar-operator"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: hangar-scout-bay is owned by scout-bay and has two available replicas"
fi
exit "$fail"
