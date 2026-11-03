#!/usr/bin/env bash
# Check: behaviour. kubectl get must show the columns REPLICAS and READY, and
# the READY column of scout-bay must show the Ready condition status.
set -uo pipefail

fail=0
header="$(kubectl -n starfleet get hangars 2>/dev/null | head -1)"
for column in REPLICAS READY; do
  if ! echo "$header" | grep -qw "$column"; then
    echo "FAIL: kubectl get hangars has no column ${column}"
    fail=1
  fi
done

columns="$(kubectl get crd hangars.fleet.astrona.io -o json 2>/dev/null \
  | jq -r '.spec.versions[] | select(.name == "v1") | .additionalPrinterColumns[]? | "\(.name)=\(.jsonPath)"')"
if ! echo "$columns" | grep -qx 'Replicas=.spec.replicas'; then
  echo "FAIL: the column Replicas must read .spec.replicas"
  fail=1
fi
if ! echo "$columns" | grep -q '^Ready=.*status.conditions'; then
  echo "FAIL: the column Ready must read the status of the Ready condition"
  fail=1
fi

row="$(kubectl -n starfleet get hangar scout-bay --no-headers 2>/dev/null || true)"
if ! echo "$row" | grep -qw "True"; then
  echo "FAIL: the row of scout-bay does not show Ready True: ${row:-no row}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: kubectl get hangars shows the Replicas and Ready columns"
fi
exit "$fail"
