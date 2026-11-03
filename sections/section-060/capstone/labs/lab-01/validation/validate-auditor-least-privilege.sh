#!/usr/bin/env bash
# Check: the auditor service account can get bridge-credentials and nothing
# more on Secrets. Rejects a Role without resourceNames, the list verb and a
# grant in another namespace.
set -uo pipefail

who="system:serviceaccount:starfleet:auditor"

answer() {
  kubectl auth can-i "$@" --as="$who" 2>/dev/null || true
}

if [ "$(answer get secret/bridge-credentials -n starfleet)" != "yes" ]; then
  echo "FAIL: auditor cannot get the Secret bridge-credentials"
  exit 1
fi
if [ "$(answer get secret/bridge-registry -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can read bridge-registry, the rule must name only bridge-credentials"
  exit 1
fi
if [ "$(answer list secrets -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can list Secrets in starfleet, which returns every value"
  exit 1
fi
if [ "$(answer update secret/bridge-credentials -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can change the Secret bridge-credentials"
  exit 1
fi
if [ "$(answer get secret/bridge-credentials -n default)" != "no" ]; then
  echo "FAIL: auditor has Secret access outside the starfleet namespace"
  exit 1
fi

echo "PASS: auditor can get only bridge-credentials in starfleet"
