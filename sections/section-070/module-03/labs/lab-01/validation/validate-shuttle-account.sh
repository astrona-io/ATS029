#!/usr/bin/env bash
# Check: every running shuttle pod uses the shuttle service account. A
# Deployment that was changed but not rolled still has pods on default.
set -uo pipefail

if ! kubectl -n starfleet get serviceaccount shuttle >/dev/null 2>&1; then
  echo "FAIL: ServiceAccount shuttle does not exist in starfleet"
  exit 1
fi

accounts="$(kubectl -n starfleet get pods -l app=shuttle -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | .spec.serviceAccountName')"
if [ -z "$accounts" ]; then
  echo "FAIL: no running shuttle pods found"
  exit 1
fi

fail=0
for account in $accounts; do
  if [ "$account" != "shuttle" ]; then
    echo "FAIL: a shuttle pod uses account '${account}', expected shuttle (roll the Deployment)"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle pods run as the shuttle service account"
fi
exit "$fail"
