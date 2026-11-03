#!/usr/bin/env bash
# Check: behaviour. Server-side dry runs (nothing is created). Bad Beacons are
# rejected with a validation error, and a valid one is accepted with the
# default mode. A CRD without validation, or with the wrong bounds, fails.
set -uo pipefail

if ! kubectl get crd beacons.signals.astrona.io >/dev/null 2>&1; then
  echo "FAIL: the CRD beacons.signals.astrona.io does not exist"
  exit 1
fi

fail=0

expect_rejected() {
  local description="$1"
  local spec="$2"
  local output
  output="$(printf 'apiVersion: signals.astrona.io/v1\nkind: Beacon\nmetadata:\n  name: grader-beacon\n  namespace: starfleet\nspec:\n%s\n' "$spec" \
    | kubectl create --dry-run=server -f - 2>&1)"
  local status=$?
  if [ "$status" -eq 0 ]; then
    echo "FAIL: the API server accepted a Beacon with $description"
    fail=1
  elif ! echo "$output" | grep -Eqi 'invalid|unsupported value|required value'; then
    echo "FAIL: the Beacon with $description was refused, but not by schema validation: $output"
    fail=1
  fi
}

expect_rejected "no frequencyMhz" "  mode: steady"
expect_rejected "frequencyMhz 0" "  frequencyMhz: 0"
expect_rejected "frequencyMhz 1001" "  frequencyMhz: 1001"
expect_rejected "mode chirp" "  frequencyMhz: 10
  mode: chirp"

accepted="$(printf 'apiVersion: signals.astrona.io/v1\nkind: Beacon\nmetadata:\n  name: grader-beacon\n  namespace: starfleet\nspec:\n  frequencyMhz: 1000\n' \
  | kubectl create --dry-run=server -f - -o jsonpath='{.spec.mode}' 2>&1)"
status=$?
if [ "$status" -ne 0 ]; then
  echo "FAIL: the API server rejected a valid Beacon with frequencyMhz 1000: $accepted"
  fail=1
elif [ "$accepted" != "steady" ]; then
  echo "FAIL: a Beacon without mode got '${accepted}', expected the default 'steady'"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: bad Beacons are rejected and the default mode is steady"
fi
exit "$fail"
