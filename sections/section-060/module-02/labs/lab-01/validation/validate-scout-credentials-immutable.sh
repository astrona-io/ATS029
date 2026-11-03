#!/usr/bin/env bash
# Check: scout-credentials is immutable. Proves it with a server-side dry run
# of a change, so the check itself never modifies the Secret.
set -uo pipefail

flag="$(kubectl -n starfleet get secret scout-credentials -o jsonpath='{.immutable}' 2>/dev/null || true)"
if [ "$flag" != "true" ]; then
  echo "FAIL: scout-credentials has immutable='${flag}', expected true"
  exit 1
fi

if kubectl -n starfleet patch secret scout-credentials --dry-run=server \
     -p '{"stringData":{"api-key":"changed-by-check"}}' >/dev/null 2>&1; then
  echo "FAIL: a change to scout-credentials was accepted, so it is not immutable"
  exit 1
fi

echo "PASS: scout-credentials is immutable and rejects changes"
