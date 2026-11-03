#!/usr/bin/env bash
# Check: the Secrets were not edited to make the other checks pass, and the
# probe pod is running. Rejects changing the Secret value to match a plain
# value or deleting a Secret.
set -uo pipefail

password="$(kubectl -n starfleet get secret probe-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode 2>/dev/null || true)"
if [ "$password" != "Plain-3030" ]; then
  echo "FAIL: the password in probe-credentials was changed or the Secret is missing"
  exit 1
fi

if ! kubectl -n starfleet get secret probe-certificate >/dev/null 2>&1; then
  echo "FAIL: the Secret probe-certificate is missing"
  exit 1
fi

phase="$(kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null || true)"
if [ -z "$phase" ]; then
  echo "FAIL: no probe pod is running"
  exit 1
fi

echo "PASS: both Secrets are intact and a probe pod is running"
