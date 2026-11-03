#!/usr/bin/env bash
# Check: behaviour. The rule does not reject valid requests and stays inside
# outpost. Rejects a policy that denies everything and a binding that selects
# every namespace.
set -uo pipefail

# The scope is only meaningful when the rule works in outpost.
enforced=1
for attempt in $(seq 1 15); do
  if ! kubectl -n outpost create deployment scope-check --image=busybox:1.37.0 \
      --replicas=5 --dry-run=server >/dev/null 2>&1; then
    enforced=0
    break
  fi
  sleep 2
done
if [ "$enforced" -ne 0 ]; then
  echo "FAIL: the rule is not enforced in outpost yet, so its scope cannot be judged"
  exit 1
fi

for replicas in 1 3; do
  if ! kubectl -n outpost create deployment scope-check --image=busybox:1.37.0 \
      --replicas="$replicas" --dry-run=server >/dev/null 2>&1; then
    echo "FAIL: a Deployment with ${replicas} replicas is rejected in outpost"
    exit 1
  fi
done

if ! kubectl -n starfleet create deployment scope-check --image=busybox:1.37.0 \
    --replicas=5 --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: a Deployment with 5 replicas is rejected in starfleet; the binding must select only outpost"
  exit 1
fi

if ! kubectl -n outpost run scope-pod --image=busybox:1.37.0 --restart=Never \
    --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: a plain pod is rejected in outpost; the policy must match only Deployments"
  exit 1
fi

echo "PASS: the rule allows up to 3 replicas and applies only in outpost"
