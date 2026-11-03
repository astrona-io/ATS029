#!/usr/bin/env bash
# Check: the shuttle account is read-only on pods. It must be able to read,
# and it must not be able to change or delete.
set -uo pipefail

as="system:serviceaccount:starfleet:shuttle"
fail=0

for verb in get list watch; do
  answer="$(kubectl auth can-i "$verb" pods -n starfleet --as="$as" 2>/dev/null || true)"
  if [ "$answer" != "yes" ]; then
    echo "FAIL: can-i $verb pods answered '${answer}', expected yes"
    fail=1
  fi
done

for verb in create update patch delete deletecollection; do
  answer="$(kubectl auth can-i "$verb" pods -n starfleet --as="$as" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: can-i $verb pods answered '${answer}', expected no"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the shuttle account can only get, list and watch pods"
fi
exit "$fail"
