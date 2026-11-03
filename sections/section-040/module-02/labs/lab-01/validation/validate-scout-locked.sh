#!/usr/bin/env bash
# Check: scout-locked is immutable, holds LOG_LEVEL=warn only, and the API
# server refuses a change to it (server-side dry run, nothing is stored).
set -uo pipefail

if ! json="$(kubectl -n starfleet get configmap scout-locked -o json 2>/dev/null)"; then
  echo "FAIL: the ConfigMap scout-locked does not exist in starfleet"
  exit 1
fi

immutable="$(echo "$json" | jq -r '.immutable // false')"
if [ "$immutable" != "true" ]; then
  echo "FAIL: scout-locked is not immutable (immutable: ${immutable})"
  exit 1
fi

keys="$(echo "$json" | jq -r '[(.data // {}), (.binaryData // {}) | keys[]] | sort | join(",")')"
level="$(echo "$json" | jq -r '.data.LOG_LEVEL // ""')"
if [ "$keys" != "LOG_LEVEL" ] || [ "$level" != "warn" ]; then
  echo "FAIL: scout-locked must hold only LOG_LEVEL=warn, found keys '${keys}' and LOG_LEVEL='${level}'"
  exit 1
fi

if kubectl -n starfleet patch configmap scout-locked --dry-run=server -p '{"data":{"LOG_LEVEL":"debug"}}' >/dev/null 2>&1; then
  echo "FAIL: the API server accepted a change to scout-locked"
  exit 1
fi

echo "PASS: scout-locked is immutable and holds LOG_LEVEL=warn"
