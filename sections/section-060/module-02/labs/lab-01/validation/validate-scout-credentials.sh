#!/usr/bin/env bash
# Check: scout-credentials exists with the exact value (no trailing newline)
# and the scout pod really received it. Rejects a ConfigMap of the same name,
# a value created with echo, and a wrong key name.
set -uo pipefail

value="$(kubectl -n starfleet get secret scout-credentials -o jsonpath='{.data.api-key}' 2>/dev/null | base64 --decode 2>/dev/null; echo x)"
value="${value%x}"
if [ "$value" != "ion-4471" ]; then
  echo "FAIL: Secret scout-credentials key api-key is not exactly 'ion-4471' (a trailing newline or a wrong key also fails)"
  exit 1
fi

if ! kubectl -n starfleet wait --for=condition=Available deployment/scout --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: Deployment scout is not available"
  exit 1
fi

inside="$(kubectl -n starfleet exec deploy/scout -- printenv API_KEY 2>/dev/null || true)"
if [ "$inside" != "ion-4471" ]; then
  echo "FAIL: the scout container sees API_KEY='${inside}', expected 'ion-4471'"
  exit 1
fi

echo "PASS: scout-credentials holds the exact value and scout is running with it"
