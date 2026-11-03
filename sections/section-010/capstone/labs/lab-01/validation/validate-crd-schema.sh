#!/usr/bin/env bash
# Check: the Hangar CRD enables the status subresource, declares the status
# fields the operator writes, and enforces 1..5 on spec.replicas. The limits are
# proven with server-side dry runs, not only by reading the schema.
set -uo pipefail

fail=0
crd="$(kubectl get crd hangars.fleet.astrona.io -o json 2>/dev/null || true)"
if [ -z "$crd" ]; then
  echo "FAIL: the CRD hangars.fleet.astrona.io does not exist"
  exit 1
fi

version="$(echo "$crd" | jq -c '.spec.versions[] | select(.name == "v1")')"
if [ -z "$version" ]; then
  echo "FAIL: the CRD has no version v1"
  exit 1
fi

if ! echo "$version" | jq -e '.subresources.status != null' >/dev/null 2>&1; then
  echo "FAIL: the status subresource is not enabled on version v1"
  fail=1
fi

status_ok="$(echo "$version" | jq -r '
  .schema.openAPIV3Schema.properties.status.properties as $s
  | ($s.observedGeneration.type == "integer")
    and ($s.readyReplicas.type == "integer")
    and ($s.conditions.type == "array")
    and ($s.conditions.items.properties.type.type == "string")
    and ($s.conditions.items.properties.status.type == "string")' 2>/dev/null)"
if [ "$status_ok" != "true" ]; then
  echo "FAIL: the schema of status must declare observedGeneration, readyReplicas and conditions (with type and status)"
  fail=1
fi

if [ "$(echo "$crd" | jq -r '.status.conditions[]? | select(.type == "Established") | .status')" != "True" ]; then
  echo "FAIL: the CRD is not established"
  fail=1
fi

dry_run() {
  # dry_run <replicas>: ask the API server whether it accepts a Hangar with this value.
  printf 'apiVersion: fleet.astrona.io/v1\nkind: Hangar\nmetadata:\n  name: schema-probe\n  namespace: starfleet\nspec:\n  replicas: %s\n' "$1" \
    | kubectl create --dry-run=server -f - >/dev/null 2>&1
}

for value in 0 9; do
  if dry_run "$value"; then
    echo "FAIL: the API server accepts spec.replicas ${value}; the allowed range is 1 to 5"
    fail=1
  fi
done
for value in 1 5; do
  if ! dry_run "$value"; then
    echo "FAIL: the API server rejects spec.replicas ${value}, which is inside the range"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the CRD has a status subresource, a status schema and replicas limits 1 to 5"
fi
exit "$fail"
