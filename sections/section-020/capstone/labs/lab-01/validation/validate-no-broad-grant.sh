#!/usr/bin/env bash
# Check: no cluster-wide binding and no edit, admin or cluster-admin binding
# names ensign-park or bridge-crew, and the certificate has no system:masters.
set -uo pipefail

crb="$(kubectl get clusterrolebindings -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .subjects[*]}{.kind}{"/"}{.name}{" "}{end}{"\n"}{end}' 2>/dev/null \
  | grep -E '(User/ensign-park|Group/bridge-crew)( |$)' || true)"
if [ -n "$crb" ]; then
  echo "FAIL: a ClusterRoleBinding names the user or the group: ${crb}"
  exit 1
fi

rb="$(kubectl get rolebindings --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\t"}{.roleRef.name}{"\t"}{range .subjects[*]}{.kind}{"/"}{.name}{" "}{end}{"\n"}{end}' 2>/dev/null \
  | grep -E '(User/ensign-park|Group/bridge-crew)( |$)' \
  | awk -F'\t' '$2 ~ /^(cluster-admin|admin|edit)$/' || true)"
if [ -n "$rb" ]; then
  echo "FAIL: a RoleBinding gives the user or the group a broad built-in role: ${rb}"
  exit 1
fi

cert="$(kubectl get csr ensign-park -o jsonpath='{.status.certificate}' 2>/dev/null)"
if [ -n "$cert" ]; then
  subject="$(echo "$cert" | base64 -d | openssl x509 -noout -subject 2>/dev/null)"
  if echo "$subject" | grep -q 'system:masters'; then
    echo "FAIL: the certificate puts ensign-park in system:masters"
    exit 1
  fi
fi

if ! kubectl --context ensign-park auth whoami >/dev/null 2>&1; then
  echo "FAIL: ensign-park is not authenticated yet, so the grants cannot be judged"
  exit 1
fi

echo "PASS: no broad grant for ensign-park or bridge-crew"
