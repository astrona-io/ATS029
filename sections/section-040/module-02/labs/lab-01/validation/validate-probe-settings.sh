#!/usr/bin/env bash
# Check: probe-settings has LOG_LEVEL=info, still has the probe.conf key with its
# original two lines, and is not immutable. Rejects `kubectl replace` with a
# partial file, delete-and-recreate without probe.conf, and a lock.
set -uo pipefail

if ! json="$(kubectl -n starfleet get configmap probe-settings -o json 2>/dev/null)"; then
  echo "FAIL: the ConfigMap probe-settings does not exist in starfleet"
  exit 1
fi

level="$(echo "$json" | jq -r '.data.LOG_LEVEL // ""')"
if [ "$level" != "info" ]; then
  echo "FAIL: probe-settings has LOG_LEVEL='${level}', expected 'info'"
  exit 1
fi

conf="$(echo "$json" | jq -r '.data["probe.conf"] // ""')"
expected_conf="$(printf 'interval=10\ntimeout=2')"
if [ "$conf" != "$expected_conf" ]; then
  echo "FAIL: the key probe.conf is missing or changed; it must keep its two lines 'interval=10' and 'timeout=2'"
  exit 1
fi

immutable="$(echo "$json" | jq -r '.immutable // false')"
if [ "$immutable" = "true" ]; then
  echo "FAIL: probe-settings must stay mutable"
  exit 1
fi

echo "PASS: probe-settings has LOG_LEVEL=info and keeps probe.conf"
