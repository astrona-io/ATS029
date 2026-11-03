#!/usr/bin/env bash
# Check: behaviour. The outpost namespace still enforces the restricted level
# and the API server still rejects a privileged pod there. Rejects the plausible
# wrong fixes: lowering the level, removing the label or switching to warn.
set -uo pipefail

level="$(kubectl get namespace outpost -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
if [ "$level" != "restricted" ]; then
  echo "FAIL: pod-security.kubernetes.io/enforce on outpost is '${level}', expected 'restricted'"
  exit 1
fi

version="$(kubectl get namespace outpost -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null || true)"
if [ -n "$version" ] && [ "$version" != "latest" ]; then
  echo "FAIL: pod-security.kubernetes.io/enforce-version on outpost is '${version}', expected it unset or 'latest'"
  exit 1
fi

output="$(kubectl apply --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-privileged
  namespace: outpost
spec:
  containers:
    - name: debug
      image: docker.io/library/busybox:1.37.0
      command: ["sleep", "30"]
      securityContext:
        privileged: true
YAML
)"
status=$?
if [ "$status" -eq 0 ] || ! echo "$output" | grep -q 'violates PodSecurity'; then
  echo "FAIL: the API server did not reject a privileged pod in outpost with a PodSecurity error"
  exit 1
fi

echo "PASS: outpost still enforces the restricted level"
