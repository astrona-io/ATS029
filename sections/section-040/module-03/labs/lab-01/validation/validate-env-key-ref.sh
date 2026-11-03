#!/usr/bin/env bash
# Check: the probe container reads LOG_LEVEL through configMapKeyRef from
# probe-settings. Rejects a fixed value (even the right one) and a wrong key.
set -uo pipefail

if ! json="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null)"; then
  echo "FAIL: the Deployment probe does not exist in starfleet"
  exit 1
fi

entry="$(echo "$json" | jq -c '[.spec.template.spec.containers[] | select(.name == "probe") | .env[]? | select(.name == "LOG_LEVEL")] | first // empty')"
if [ -z "$entry" ]; then
  echo "FAIL: the probe container has no env entry named LOG_LEVEL"
  exit 1
fi

if [ "$(echo "$entry" | jq -r '.value // empty')" != "" ]; then
  echo "FAIL: LOG_LEVEL still has a fixed value; it must come from the ConfigMap"
  exit 1
fi

name="$(echo "$entry" | jq -r '.valueFrom.configMapKeyRef.name // ""')"
key="$(echo "$entry" | jq -r '.valueFrom.configMapKeyRef.key // ""')"
if [ "$name" != "probe-settings" ] || [ "$key" != "LOG_LEVEL" ]; then
  echo "FAIL: LOG_LEVEL must use configMapKeyRef with name probe-settings and key LOG_LEVEL (found name '${name}', key '${key}')"
  exit 1
fi

echo "PASS: LOG_LEVEL comes from the key LOG_LEVEL of probe-settings"
