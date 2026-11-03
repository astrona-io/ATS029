#!/usr/bin/env bash
# Check: DB_PASSWORD comes from the Secret, not from a plain value, and the
# running container really has the Secret value. Rejects a plain value copied
# into the pod template and a ConfigMap reference.
set -uo pipefail

spec="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null || true)"
if [ -z "$spec" ]; then
  echo "FAIL: Deployment probe not found in starfleet"
  exit 1
fi

secret_name="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="DB_PASSWORD") | .valueFrom.secretKeyRef.name // empty')"
secret_key="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="DB_PASSWORD") | .valueFrom.secretKeyRef.key // empty')"
if [ "$secret_name" != "probe-credentials" ] || [ "$secret_key" != "password" ]; then
  echo "FAIL: DB_PASSWORD must use secretKeyRef probe-credentials/password (found '${secret_name}/${secret_key}')"
  exit 1
fi

if printf '%s' "$spec" | jq -e '.spec.template | tostring | contains("Plain-3030")' >/dev/null 2>&1; then
  echo "FAIL: the plain password is still written in the pod template"
  exit 1
fi

if ! kubectl -n starfleet rollout status deployment/probe --timeout=150s >/dev/null 2>&1; then
  echo "FAIL: Deployment probe did not finish rolling out"
  exit 1
fi

inside="$(kubectl -n starfleet exec deploy/probe -- printenv DB_PASSWORD 2>/dev/null || true)"
if [ "$inside" != "Plain-3030" ]; then
  echo "FAIL: the probe container sees DB_PASSWORD='${inside}', expected the Secret value"
  exit 1
fi

echo "PASS: DB_PASSWORD comes from probe-credentials and the container has it"
