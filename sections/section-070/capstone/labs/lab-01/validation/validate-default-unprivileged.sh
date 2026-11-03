#!/usr/bin/env bash
# Check: the default account in starfleet is no longer a cluster administrator.
# Rejects a fix that deletes the account, and a fix that only removes a rule
# while another binding still grants the access.
set -uo pipefail

fail=0

if ! kubectl -n starfleet get serviceaccount default >/dev/null 2>&1; then
  echo "FAIL: the default ServiceAccount in starfleet is missing"
  exit 1
fi

answer="$(kubectl auth can-i list secrets --all-namespaces --as=system:serviceaccount:starfleet:default 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: the default account can still list Secrets in all namespaces (can-i answered '${answer}')"
  fail=1
fi

bound="$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin") | select(any(.subjects[]?; .kind == "ServiceAccount" and .name == "default" and .namespace == "starfleet")) | .metadata.name')"
if [ -n "$bound" ]; then
  echo "FAIL: cluster-admin is still bound to the default account by: $bound"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the default account in starfleet has no administrator access"
fi
exit "$fail"
