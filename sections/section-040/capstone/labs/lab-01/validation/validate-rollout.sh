#!/usr/bin/env bash
# Check: the Deployment finished its rollout with two available replicas and
# exactly two pods (no old pods left, nothing scaled).
set -uo pipefail

if ! kubectl -n starfleet rollout status deployment/scout --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the rollout of deployment/scout is not complete"
  exit 1
fi

json="$(kubectl -n starfleet get deployment scout -o json)"
desired="$(echo "$json" | jq -r '.spec.replicas')"
available="$(echo "$json" | jq -r '.status.availableReplicas // 0')"
if [ "$desired" != "2" ] || [ "$available" != "2" ]; then
  echo "FAIL: expected 2 desired and 2 available replicas, found ${desired} desired and ${available} available"
  exit 1
fi

count="$(kubectl -n starfleet get pods -l app=scout -o json \
  | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "$count" != "2" ]; then
  echo "FAIL: expected 2 scout pods, found ${count}"
  exit 1
fi

echo "PASS: deployment/scout rolled out with 2 available replicas"
