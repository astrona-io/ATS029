#!/usr/bin/env bash
# Check: behaviour of the LimitRange, tested with server-side dry runs so
# nothing is created. A pod with a 1Gi memory limit must be refused by the
# maximum, a pod with a CPU limit eight times its request must be refused by
# the ratio, and a pod with no resources must come back with the defaults.
set -uo pipefail

fail=0

max_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-over-max
  namespace: outpost
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

ratio_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-ratio
  namespace: outpost
spec:
  containers:
    - name: ratio
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 400m
          memory: 128Mi
YAML
)"
ratio_status=$?
if [ "$ratio_status" -eq 0 ] || ! echo "$ratio_output" | grep -q 'max limit to request ratio'; then
  echo "FAIL: a pod with a limit to request ratio of 8 was not rejected: ${ratio_output}"
  fail=1
fi

defaults="$(kubectl create --request-timeout=30s --dry-run=server -o jsonpath='{.spec.containers[0].resources.limits.cpu}/{.spec.containers[0].resources.limits.memory}/{.spec.containers[0].resources.requests.cpu}/{.spec.containers[0].resources.requests.memory}' -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-plain
  namespace: outpost
spec:
  containers:
    - name: plain
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
YAML
)"
if [ "$defaults" != "200m/256Mi/100m/128Mi" ]; then
  echo "FAIL: a pod with no resources did not receive the defaults (got '${defaults}', expected 200m/256Mi/100m/128Mi)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the LimitRange rejects out-of-range pods and applies the defaults"
fi
exit "$fail"
