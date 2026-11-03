#!/usr/bin/env bash
# Check: behaviour. With the quota active, a pod that requests 2 CPUs is
# refused with "exceeded quota" and a small pod is admitted. Both are
# server-side dry runs, so nothing is created. A deleted or disabled quota
# fails the first test, and a quota with no room left fails the second.
set -uo pipefail

fail=0

large_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-large
  namespace: starfleet
spec:
  containers:
    - name: large
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      resources:
        requests:
          cpu: "2"
          memory: 64Mi
        limits:
          cpu: "2"
          memory: 128Mi
YAML
)"
large_status=$?
if [ "$large_status" -eq 0 ] || ! echo "$large_output" | grep -q 'exceeded quota'; then
  echo "FAIL: a pod requesting 2 CPUs was not rejected with 'exceeded quota': ${large_output}"
  fail=1
fi

small_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-small
  namespace: starfleet
spec:
  containers:
    - name: small
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
YAML
)"
small_status=$?
if [ "$small_status" -ne 0 ]; then
  echo "FAIL: a small pod that fits the budget was rejected: ${small_output}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the quota rejects an over-budget pod and admits a small pod"
fi
exit "$fail"
