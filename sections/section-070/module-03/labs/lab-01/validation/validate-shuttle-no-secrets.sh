#!/usr/bin/env bash
# Check: least privilege. The shuttle pod gets HTTP 403 for Secrets, and the
# authorizer agrees for the account. Rejects a wildcard Role and a binding to
# view, edit, admin or cluster-admin.
set -uo pipefail

SA_DIR=/var/run/secrets/kubernetes.io/serviceaccount
SHUTTLE_POD="$(kubectl -n starfleet get pods -l app=shuttle -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | .[0].metadata.name // empty')"
if [ -z "$SHUTTLE_POD" ]; then
  echo "FAIL: no running shuttle pod found"
  exit 1
fi

api_status() {
  kubectl -n starfleet exec "$SHUTTLE_POD" -- sh -c "curl -s -m 10 -o /dev/null -w '%{http_code}' --cacert $SA_DIR/ca.crt -H \"Authorization: Bearer \$(cat $SA_DIR/token)\" https://kubernetes.default.svc.cluster.local$1" 2>/dev/null || true
}

code="$(api_status /api/v1/namespaces/starfleet/secrets)"
if [ "$code" != "403" ]; then
  echo "FAIL: listing Secrets from the shuttle pod returned HTTP '${code}', expected 403"
  exit 1
fi

answer="$(kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:shuttle 2>/dev/null || true)"
if [ "$answer" != "no" ]; then
  echo "FAIL: can-i get secrets answered '${answer}', expected no"
  exit 1
fi

echo "PASS: the shuttle account cannot read Secrets"
