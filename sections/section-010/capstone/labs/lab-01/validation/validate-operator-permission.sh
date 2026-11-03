#!/usr/bin/env bash
# Check: behaviour. Impersonates the operator's service account. It must be
# allowed to create and patch Deployments, and must not have more than that:
# no delete, no Secrets, no Pods, no wildcard, no cluster-admin/admin/edit.
set -uo pipefail

operator="system:serviceaccount:fleet-system:hangar-operator"
fail=0

allowed() {
  kubectl auth can-i "$1" "$2" -n starfleet --as="$operator" 2>/dev/null
}

for verb in get list watch create patch; do
  if [ "$(allowed "$verb" deployments.apps)" != "yes" ]; then
    echo "FAIL: the operator cannot $verb deployments in starfleet"
    fail=1
  fi
done

for denied in "delete deployments.apps" "get secrets" "create pods" "create clusterrolebindings.rbac.authorization.k8s.io"; do
  # shellcheck disable=SC2086
  if [ "$(allowed $denied)" = "yes" ]; then
    echo "FAIL: the operator may '$denied' in starfleet, which is more than it needs"
    fail=1
  fi
done

if [ "$(kubectl auth can-i '*' '*' --as="$operator" 2>/dev/null)" = "yes" ]; then
  echo "FAIL: the operator may do everything (wildcard or cluster-admin)"
  fail=1
fi

bindings="$( { kubectl get clusterrolebindings -o json; kubectl get rolebindings -A -o json; } 2>/dev/null \
  | jq -r '.items[]
      | select(.roleRef.name | IN("cluster-admin", "admin", "edit"))
      | select(.subjects[]? | .kind == "ServiceAccount" and .name == "hangar-operator" and .namespace == "fleet-system")
      | .metadata.name')"
if [ -n "$bindings" ]; then
  echo "FAIL: the operator is bound to a broad role through: $bindings"
  fail=1
fi

if ! kubectl get clusterrole hangar-operator -o json 2>/dev/null | jq -e '[.rules[] | (.verbs + .resources + .apiGroups)[] | select(. == "*")] | length == 0' >/dev/null 2>&1; then
  echo "FAIL: the ClusterRole hangar-operator is missing or has a wildcard"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the operator can create and patch Deployments and has no extra rights"
fi
exit "$fail"
