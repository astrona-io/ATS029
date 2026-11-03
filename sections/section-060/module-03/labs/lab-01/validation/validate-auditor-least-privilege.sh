#!/usr/bin/env bash
# Check: the auditor service account can get probe-credentials and nothing more
# on Secrets. Rejects a Role without resourceNames, a list verb and a cluster
# wide grant.
set -uo pipefail

who="system:serviceaccount:starfleet:auditor"

answer() {
  kubectl auth can-i "$@" --as="$who" 2>/dev/null || true
}

if [ "$(answer get secret/probe-credentials -n starfleet)" != "yes" ]; then
  echo "FAIL: auditor cannot get the Secret probe-credentials"
  exit 1
fi
if [ "$(answer get secret/probe-certificate -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can read the Secret probe-certificate, the rule must name only probe-credentials"
  exit 1
fi
if [ "$(answer list secrets -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can list Secrets in starfleet, which returns every value"
  exit 1
fi
if [ "$(answer delete secret/probe-credentials -n starfleet)" != "no" ]; then
  echo "FAIL: auditor can delete the Secret probe-credentials"
  exit 1
fi
if [ "$(answer get secret/probe-credentials -n default)" != "no" ]; then
  echo "FAIL: auditor has Secret access outside the starfleet namespace"
  exit 1
fi

echo "PASS: auditor can get only probe-credentials in starfleet"
