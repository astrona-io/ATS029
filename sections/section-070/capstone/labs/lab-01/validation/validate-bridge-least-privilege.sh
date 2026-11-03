#!/usr/bin/env bash
# Check: least privilege for bridge. HTTP 403 for Secrets from inside the pod,
# and the authorizer says no for write verbs and for other namespaces.
set -uo pipefail

BRIDGE_POD="$(kubectl -n starfleet get pods -l app=bridge -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | .[0].metadata.name // empty')"
if [ -z "$BRIDGE_POD" ]; then
  echo "FAIL: no running bridge pod found"
  exit 1
fi
SA_DIR=/var/run/secrets/kubernetes.io/serviceaccount

code="$(kubectl -n starfleet exec "$BRIDGE_POD" -- sh -c "curl -s -m 10 -o /dev/null -w '%{http_code}' --cacert $SA_DIR/ca.crt -H \"Authorization: Bearer \$(cat $SA_DIR/token)\" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/starfleet/secrets" 2>/dev/null || true)"
if [ "$code" != "403" ]; then
  echo "FAIL: listing Secrets from the bridge pod returned HTTP '${code}', expected 403"
  exit 1
fi

as="system:serviceaccount:starfleet:bridge"
fail=0

for verb in create update patch delete; do
  answer="$(kubectl auth can-i "$verb" pods -n starfleet --as="$as" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: can-i $verb pods answered '${answer}', expected no"
    fail=1
  fi
done

answer="$(kubectl auth can-i list pods -n kube-system --as="$as" 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: bridge can list pods in kube-system (can-i answered '${answer}'), use a Role and a RoleBinding in starfleet"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: bridge has read-only access to pods in starfleet and nothing else"
fi
exit "$fail"
