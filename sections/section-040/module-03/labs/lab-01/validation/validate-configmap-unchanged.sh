#!/usr/bin/env bash
# Check: probe-settings still holds its original data. Rejects the shortcut of
# editing the ConfigMap to fit the Deployment.
set -uo pipefail

if ! json="$(kubectl -n starfleet get configmap probe-settings -o json 2>/dev/null)"; then
  echo "FAIL: the ConfigMap probe-settings does not exist in starfleet"
  exit 1
fi

keys="$(echo "$json" | jq -r '[(.data // {}), (.binaryData // {}) | keys[]] | sort | join(",")')"
level="$(echo "$json" | jq -r '.data.LOG_LEVEL // ""')"
region="$(echo "$json" | jq -r '.data.REGION // ""')"
properties="$(echo "$json" | jq -r '.data["probe.properties"] // ""')"
if [ "$keys" != "LOG_LEVEL,REGION,probe.properties" ] || [ "$level" != "debug" ] || [ "$region" != "outpost-7" ] || [ "$properties" != "retries=3" ]; then
  echo "FAIL: probe-settings was changed; it must keep LOG_LEVEL=debug, REGION=outpost-7 and probe.properties=retries=3"
  exit 1
fi

echo "PASS: probe-settings is unchanged"
