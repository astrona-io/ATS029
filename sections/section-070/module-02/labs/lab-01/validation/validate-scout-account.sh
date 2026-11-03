#!/usr/bin/env bash
# Check: the scout service account exists in starfleet and the account itself
# switches the token mount off.
set -uo pipefail

if ! kubectl -n starfleet get serviceaccount scout >/dev/null 2>&1; then
  echo "FAIL: ServiceAccount scout does not exist in starfleet"
  exit 1
fi

value="$(kubectl -n starfleet get serviceaccount scout -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "$value" != "false" ]; then
  echo "FAIL: automountServiceAccountToken on the scout account is '${value}', expected false"
  exit 1
fi

default_value="$(kubectl -n starfleet get serviceaccount default -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "$default_value" = "false" ]; then
  echo "FAIL: the default account must not be changed (automountServiceAccountToken is false on it)"
  exit 1
fi

echo "PASS: scout account exists with automountServiceAccountToken=false"
