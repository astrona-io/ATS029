#!/usr/bin/env bash
# Check: behaviour. A real request from inside the bridge pod, using its
# mounted token, lists pods in starfleet with HTTP 200. This fails when the
# pod still runs as default, when the binding names the wrong subject, and
# when the Role is in the wrong namespace.
set -uo pipefail

SA_DIR=/var/run/secrets/kubernetes.io/serviceaccount
BRIDGE_POD="$(kubectl -n starfleet get pods -l app=bridge -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | .[0].metadata.name // empty')"
if [ -z "$BRIDGE_POD" ]; then
  echo "FAIL: no running bridge pod found"
  exit 1
fi

api_status() {
  kubectl -n starfleet exec "$BRIDGE_POD" -- sh -c "curl -s -m 10 -o /dev/null -w '%{http_code}' --cacert $SA_DIR/ca.crt -H \"Authorization: Bearer \$(cat $SA_DIR/token)\" https://kubernetes.default.svc.cluster.local$1" 2>/dev/null || true
}

code="$(api_status /api/v1/namespaces/starfleet/pods)"
if [ "$code" != "200" ]; then
  echo "FAIL: listing pods from the bridge pod returned HTTP '${code}', expected 200"
  exit 1
fi

echo "PASS: the bridge pod lists pods in starfleet (HTTP 200)"
