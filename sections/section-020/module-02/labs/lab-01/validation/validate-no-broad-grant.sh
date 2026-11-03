#!/usr/bin/env bash
# Check: no ClusterRoleBinding names ensign-lee, and the certificate does not
# put the user in system:masters (which would bypass RBAC).
set -uo pipefail

bad="$(kubectl get clusterrolebindings -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .subjects[*]}{.kind}{"/"}{.name}{" "}{end}{"\n"}{end}' 2>/dev/null | grep -E '(^|[ \t])User/ensign-lee( |$)' || true)"
if [ -n "$bad" ]; then
  echo "FAIL: a ClusterRoleBinding names ensign-lee: ${bad}"
  exit 1
fi

cert="$(kubectl get csr ensign-lee -o jsonpath='{.status.certificate}' 2>/dev/null)"
if [ -n "$cert" ]; then
  subject="$(echo "$cert" | base64 -d | openssl x509 -noout -subject 2>/dev/null)"
  if echo "$subject" | grep -q 'system:masters'; then
    echo "FAIL: the certificate puts ensign-lee in system:masters"
    exit 1
  fi
fi

if ! kubectl --context ensign-lee auth whoami >/dev/null 2>&1; then
  echo "FAIL: ensign-lee is not authenticated yet, so the grants cannot be judged"
  exit 1
fi

echo "PASS: no cluster-wide grant for ensign-lee"
