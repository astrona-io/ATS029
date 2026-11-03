#!/usr/bin/env bash
# Check: scout-files has the key app.properties (chosen key, two lines) and the
# key banner.txt. Rejects the default key name scout.properties.
set -uo pipefail

if ! json="$(kubectl -n starfleet get configmap scout-files -o json 2>/dev/null)"; then
  echo "FAIL: the ConfigMap scout-files does not exist in starfleet"
  exit 1
fi

keys="$(echo "$json" | jq -r '[(.data // {}), (.binaryData // {}) | keys[]] | sort | join(",")')"
if [ "$keys" != "app.properties,banner.txt" ]; then
  echo "FAIL: scout-files has the keys '${keys}', expected exactly 'app.properties,banner.txt'"
  exit 1
fi

properties="$(echo "$json" | jq -r '.data["app.properties"]')"
expected_properties="$(printf 'retries=3\nregion=outpost-7')"
if [ "$properties" != "$expected_properties" ]; then
  echo "FAIL: the value of app.properties is not the two lines 'retries=3' and 'region=outpost-7'"
  exit 1
fi

banner="$(echo "$json" | jq -r '.data["banner.txt"]')"
if [ "$banner" != "scout online" ]; then
  echo "FAIL: the value of banner.txt is '${banner}', expected 'scout online'"
  exit 1
fi

echo "PASS: scout-files has app.properties and banner.txt with the right content"
