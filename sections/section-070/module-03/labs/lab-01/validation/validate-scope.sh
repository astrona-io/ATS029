#!/usr/bin/env bash
# Check: scope. The permission exists only in starfleet, and the default
# account was not given the rule instead of creating a new account.
set -uo pipefail

fail=0

answer="$(kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:shuttle 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: shuttle can list pods in outpost (can-i answered '${answer}'), use a Role and a RoleBinding in starfleet"
  fail=1
fi

answer="$(kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:starfleet:shuttle 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: shuttle can list pods in all namespaces (can-i answered '${answer}')"
  fail=1
fi

answer="$(kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:default 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: the default account can list pods in starfleet (can-i answered '${answer}'), give the permission to shuttle only"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: access is limited to the shuttle account in starfleet"
fi
exit "$fail"
