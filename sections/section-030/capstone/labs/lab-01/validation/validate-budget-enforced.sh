#!/usr/bin/env bash
# Check: behaviour, tested with server-side dry runs so nothing is created.
# A pod requesting 512Mi of memory fits the LimitRange maximum but not the
# memory left in the quota, so it must be refused with "exceeded quota". A pod
# with a 1Gi memory limit must be refused by the LimitRange maximum. A pod with
# no resources must be admitted and come back with the defaults.
set -uo pipefail

fail=0

quota_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-over-budget
  namespace: starfleet
spec:
  containers:
    - name: over-budget
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      resources:
        requests:
          cpu: 100m
          memory: 512Mi
        limits:
          cpu: 100m
          memory: 512Mi
YAML
)"
quota_status=$?
if [ "$quota_status" -eq 0 ] || ! echo "$quota_output" | grep -q 'exceeded quota'; then
  echo "FAIL: a pod requesting 512Mi of memory was not rejected with 'exceeded quota': ${quota_output}"
  fail=1
fi

max_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-over-max
  namespace: starfleet
spec:
  containers:
    - name: over-max
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 100m
          memory: 1Gi
YAML
)"
max_status=$?
if [ "$max_status" -eq 0 ] || ! echo "$max_output" | grep -q 'maximum memory usage per Container'; then
  echo "FAIL: a pod with a 1Gi memory limit was not rejected by the maximum: ${max_output}"
  fail=1
fi

defaults="$(kubectl create --request-timeout=30s --dry-run=server -o jsonpath='{.spec.containers[0].resources.limits.cpu}/{.spec.containers[0].resources.limits.memory}/{.spec.containers[0].resources.requests.cpu}/{.spec.containers[0].resources.requests.memory}' -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-plain
  namespace: starfleet
spec:
  containers:
    - name: plain
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
YAML
)"
if [ "$defaults" != "200m/256Mi/100m/128Mi" ]; then
  echo "FAIL: a pod with no resources was not admitted with the defaults (got '${defaults}', expected 200m/256Mi/100m/128Mi)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the quota and the LimitRange refuse oversized pods and apply the defaults"
fi
exit "$fail"
