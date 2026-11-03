#!/usr/bin/env bash
# Check: bridge-settings has exactly the keys REGION and TIER with exact values.
# Rejects a Secret created with --from-file (one key holding the whole file).
set -uo pipefail

names="$(kubectl -n starfleet get secret bridge-settings -o json 2>/dev/null | jq -r '.data | keys | join(",")' 2>/dev/null || true)"
if [ -z "$names" ]; then
  echo "FAIL: Secret bridge-settings does not exist in starfleet"
  exit 1
fi
if [ "$names" != "REGION,TIER" ]; then
  echo "FAIL: bridge-settings keys are '${names}', expected exactly 'REGION,TIER'"
  exit 1
fi

region="$(kubectl -n starfleet get secret bridge-settings -o jsonpath='{.data.REGION}' | base64 --decode)"
tier="$(kubectl -n starfleet get secret bridge-settings -o jsonpath='{.data.TIER}' | base64 --decode)"
if [ "$region" != "outpost-4" ] || [ "$tier" != "gold" ]; then
  echo "FAIL: values are REGION='${region}' TIER='${tier}', expected 'outpost-4' and 'gold'"
  exit 1
fi

echo "PASS: bridge-settings has REGION and TIER with the right values"
