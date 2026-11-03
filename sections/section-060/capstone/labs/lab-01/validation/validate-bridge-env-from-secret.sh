#!/usr/bin/env bash
# Check: BRIDGE_PASSWORD comes from the Secret and the running container has the
# rotated value. Rejects a plain value, and a Secret update without a rollout
# (the old pod still holds the old password).
set -uo pipefail

spec="$(kubectl -n starfleet get deployment bridge -o json 2>/dev/null || true)"
if [ -z "$spec" ]; then
  echo "FAIL: Deployment bridge not found in starfleet"
  exit 1
fi

secret_name="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="BRIDGE_PASSWORD") | .valueFrom.secretKeyRef.name // empty')"
secret_key="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="BRIDGE_PASSWORD") | .valueFrom.secretKeyRef.key // empty')"
if [ "$secret_name" != "bridge-credentials" ] || [ "$secret_key" != "password" ]; then
  echo "FAIL: BRIDGE_PASSWORD must use secretKeyRef bridge-credentials/password (found '${secret_name}/${secret_key}')"
  exit 1
fi

if printf '%s' "$spec" | jq -e '.spec.template | tostring | (contains("Old-1000") or contains("Pulsar-2026"))' >/dev/null 2>&1; then
  echo "FAIL: a password is still written as a plain value in the pod template"
  exit 1
fi

if ! kubectl -n starfleet rollout status deployment/bridge --timeout=150s >/dev/null 2>&1; then
  echo "FAIL: Deployment bridge did not finish rolling out"
  exit 1
fi

inside="$(kubectl -n starfleet exec deploy/bridge -- printenv BRIDGE_PASSWORD 2>/dev/null || true)"
if [ "$inside" != "Pulsar-2026" ]; then
  echo "FAIL: the bridge container sees BRIDGE_PASSWORD='${inside}', expected 'Pulsar-2026' (restart the pods after the rotation)"
  exit 1
fi

echo "PASS: BRIDGE_PASSWORD comes from bridge-credentials and holds the rotated value"
