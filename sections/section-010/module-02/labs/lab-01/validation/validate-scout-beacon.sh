#!/usr/bin/env bash
# Check: scout-beacon exists in starfleet with the requested values and works
# with the short name.
set -uo pipefail

fail=0

frequency="$(kubectl get bcn scout-beacon -n starfleet -o jsonpath='{.spec.frequencyMhz}' 2>/dev/null || true)"
mode="$(kubectl get bcn scout-beacon -n starfleet -o jsonpath='{.spec.mode}' 2>/dev/null || true)"
api_version="$(kubectl get bcn scout-beacon -n starfleet -o jsonpath='{.apiVersion}' 2>/dev/null || true)"

if [ -z "$api_version" ]; then
  echo "FAIL: the Beacon scout-beacon was not found in starfleet (with the short name bcn)"
  exit 1
fi
if [ "$api_version" != "signals.astrona.io/v1" ]; then
  echo "FAIL: scout-beacon has apiVersion '${api_version}', expected signals.astrona.io/v1"
  fail=1
fi
if [ "$frequency" != "120" ]; then
  echo "FAIL: scout-beacon has frequencyMhz '${frequency}', expected 120"
  fail=1
fi
if [ "$mode" != "pulse" ]; then
  echo "FAIL: scout-beacon has mode '${mode}', expected pulse"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-beacon exists in starfleet with frequencyMhz 120 and mode pulse"
fi
exit "$fail"
