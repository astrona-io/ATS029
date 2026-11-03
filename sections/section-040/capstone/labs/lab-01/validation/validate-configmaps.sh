#!/usr/bin/env bash
# Check: scout-config-v1 and scout-config-v2 both exist, are immutable and hold
# LOG_LEVEL, REGION and scout.conf. v1 keeps info, v2 has debug. Rejects an
# in-place edit of one ConfigMap and mutable objects.
set -uo pipefail

check_version() {
  local name="$1"
  local expected_level="$2"
  local json
  if ! json="$(kubectl -n starfleet get configmap "$name" -o json 2>/dev/null)"; then
    echo "FAIL: the ConfigMap ${name} does not exist in starfleet"
    return 1
  fi
  if [ "$(echo "$json" | jq -r '.immutable // false')" != "true" ]; then
    echo "FAIL: ${name} is not immutable"
    return 1
  fi
  local keys
  keys="$(echo "$json" | jq -r '[(.data // {}), (.binaryData // {}) | keys[]] | sort | join(",")')"
  if [ "$keys" != "LOG_LEVEL,REGION,scout.conf" ]; then
    echo "FAIL: ${name} has the keys '${keys}', expected 'LOG_LEVEL,REGION,scout.conf'"
    return 1
  fi
  local level region conf expected_conf
  level="$(echo "$json" | jq -r '.data.LOG_LEVEL')"
  region="$(echo "$json" | jq -r '.data.REGION')"
  conf="$(echo "$json" | jq -r '.data["scout.conf"]')"
  expected_conf="$(printf 'interval=10\ntimeout=2')"
  if [ "$level" != "$expected_level" ] || [ "$region" != "outpost-7" ] || [ "$conf" != "$expected_conf" ]; then
    echo "FAIL: ${name} has the wrong values (LOG_LEVEL='${level}', REGION='${region}'); expected LOG_LEVEL=${expected_level}, REGION=outpost-7 and scout.conf with 'interval=10' and 'timeout=2'"
    return 1
  fi
  return 0
}

fail=0
check_version scout-config-v1 info || fail=1
check_version scout-config-v2 debug || fail=1

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-config-v1 (info) and scout-config-v2 (debug) are immutable with the right keys"
fi
exit "$fail"
