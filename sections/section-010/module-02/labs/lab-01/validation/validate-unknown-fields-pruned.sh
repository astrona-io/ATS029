#!/usr/bin/env bash
# Check: behaviour. With strict validation off, a field that the schema does
# not declare must not be stored. Rejects the plausible wrong fix of setting
# x-kubernetes-preserve-unknown-fields.
set -uo pipefail

crd_json="$(kubectl get crd beacons.signals.astrona.io -o json 2>/dev/null || true)"
if [ -z "$crd_json" ]; then
  echo "FAIL: the CRD beacons.signals.astrona.io does not exist"
  exit 1
fi

fail=0

if echo "$crd_json" | jq -e '[.. | objects | select(has("x-kubernetes-preserve-unknown-fields")) | ."x-kubernetes-preserve-unknown-fields"] | any' >/dev/null 2>&1; then
  echo "FAIL: the schema sets x-kubernetes-preserve-unknown-fields to true"
  fail=1
fi

stored="$(printf 'apiVersion: signals.astrona.io/v1\nkind: Beacon\nmetadata:\n  name: grader-beacon\n  namespace: starfleet\nspec:\n  frequencyMhz: 10\n  colour: red\n' \
  | kubectl create --dry-run=server --validate=false -f - -o jsonpath='{.spec.colour}' 2>&1)"
status=$?
if [ "$status" -ne 0 ]; then
  echo "FAIL: a dry run of a valid Beacon with an extra field failed: $stored"
  fail=1
elif [ -n "$stored" ]; then
  echo "FAIL: the field spec.colour was stored as '${stored}'; unknown fields must be dropped"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: unknown fields are not stored"
fi
exit "$fail"
