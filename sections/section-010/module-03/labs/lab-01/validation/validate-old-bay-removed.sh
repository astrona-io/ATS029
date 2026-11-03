#!/usr/bin/env bash
# Check: old-bay is gone and the CRD was not deleted to get there.
set -uo pipefail

fail=0

if kubectl -n starfleet get hangar old-bay >/dev/null 2>&1; then
  finalizers="$(kubectl -n starfleet get hangar old-bay -o jsonpath='{.metadata.finalizers}' 2>/dev/null || true)"
  echo "FAIL: the Hangar old-bay still exists (finalizers: ${finalizers:-none})"
  fail=1
fi

established="$(kubectl get crd hangars.fleet.astrona.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null || true)"
if [ "$established" != "True" ]; then
  echo "FAIL: the CRD hangars.fleet.astrona.io is missing or not established"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: old-bay is removed and the CRD is intact"
fi
exit "$fail"
