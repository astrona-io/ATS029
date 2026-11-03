#!/usr/bin/env bash
# Check: scout-env has exactly the keys MODE and RETRIES with the right values.
# Rejects --from-file (one key named after the file) and extra keys.
set -uo pipefail

if ! json="$(kubectl -n starfleet get configmap scout-env -o json 2>/dev/null)"; then
  echo "FAIL: the ConfigMap scout-env does not exist in starfleet"
  exit 1
fi

keys="$(echo "$json" | jq -r '[(.data // {}), (.binaryData // {}) | keys[]] | sort | join(",")')"
if [ "$keys" != "MODE,RETRIES" ]; then
  echo "FAIL: scout-env has the keys '${keys}', expected exactly 'MODE,RETRIES' (one key for each line of an environment file)"
  exit 1
fi

mode="$(echo "$json" | jq -r '.data.MODE')"
retries="$(echo "$json" | jq -r '.data.RETRIES')"
if [ "$mode" != "fast" ] || [ "$retries" != "3" ]; then
  echo "FAIL: scout-env has MODE='${mode}' and RETRIES='${retries}', expected 'fast' and '3'"
  exit 1
fi

echo "PASS: scout-env has the keys MODE and RETRIES with the right values"
