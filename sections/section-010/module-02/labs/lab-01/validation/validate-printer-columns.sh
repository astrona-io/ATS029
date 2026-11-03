#!/usr/bin/env bash
# Check: the CRD defines the Frequency and Mode printer columns, and
# `kubectl get beacons` prints them with the values of scout-beacon.
set -uo pipefail

crd_json="$(kubectl get crd beacons.signals.astrona.io -o json 2>/dev/null || true)"
if [ -z "$crd_json" ]; then
  echo "FAIL: the CRD beacons.signals.astrona.io does not exist"
  exit 1
fi

fail=0

if ! echo "$crd_json" | jq -e '.spec.versions[] | select(.name == "v1") | .additionalPrinterColumns[]? | select(.name == "Frequency" and .type == "integer" and .jsonPath == ".spec.frequencyMhz")' >/dev/null 2>&1; then
  echo "FAIL: the column Frequency (integer, .spec.frequencyMhz) is missing"
  fail=1
fi
if ! echo "$crd_json" | jq -e '.spec.versions[] | select(.name == "v1") | .additionalPrinterColumns[]? | select(.name == "Mode" and .type == "string" and .jsonPath == ".spec.mode")' >/dev/null 2>&1; then
  echo "FAIL: the column Mode (string, .spec.mode) is missing"
  fail=1
fi

table="$(kubectl get beacons -n starfleet 2>/dev/null || true)"
header="$(echo "$table" | head -n 1)"
if ! echo "$header" | grep -q 'FREQUENCY' || ! echo "$header" | grep -q 'MODE'; then
  echo "FAIL: kubectl get beacons does not print the columns FREQUENCY and MODE"
  fail=1
elif ! echo "$table" | grep '^scout-beacon' | grep -Eq '(^|[[:space:]])120([[:space:]]|$)' \
  || ! echo "$table" | grep '^scout-beacon' | grep -Eq '(^|[[:space:]])pulse([[:space:]]|$)'; then
  echo "FAIL: the row of scout-beacon does not show 120 and pulse"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: kubectl get beacons prints the Frequency and Mode columns"
fi
exit "$fail"
