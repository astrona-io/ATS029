#!/usr/bin/env bash
# Check: the Beacon CRD exists, is established and has the required names,
# scope, version and status subresource.
set -uo pipefail

crd_json="$(kubectl get crd beacons.signals.astrona.io -o json 2>/dev/null || true)"
if [ -z "$crd_json" ]; then
  echo "FAIL: the CRD beacons.signals.astrona.io does not exist"
  exit 1
fi

fail=0
check() {
  local description="$1"
  local filter="$2"
  if ! echo "$crd_json" | jq -e "$filter" >/dev/null 2>&1; then
    echo "FAIL: $description"
    fail=1
  fi
}

check "the CRD is not Established" '.status.conditions[]? | select(.type == "Established" and .status == "True")'
check "spec.group is not signals.astrona.io" '.spec.group == "signals.astrona.io"'
check "spec.scope is not Namespaced" '.spec.scope == "Namespaced"'
check "names.kind is not Beacon" '.spec.names.kind == "Beacon"'
check "names.plural is not beacons" '.spec.names.plural == "beacons"'
check "names.singular is not beacon" '.spec.names.singular == "beacon"'
check "the short name bcn is missing" '(.spec.names.shortNames // []) | index("bcn")'
check "version v1 is not served and stored" '.spec.versions[] | select(.name == "v1" and .served == true and .storage == true)'
check "the status subresource is not enabled on v1" '.spec.versions[] | select(.name == "v1") | .subresources.status != null'

if [ "$fail" -eq 0 ]; then
  echo "PASS: the Beacon CRD is established with the required names, scope, version and status subresource"
fi
exit "$fail"
