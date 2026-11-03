#!/usr/bin/env bash
# Check: behaviour. No live bridge pod uses the host network, the host PID or
# IPC namespaces, or a hostPath volume.
set -uo pipefail

pods="$(kubectl -n outpost get pods -l app=bridge --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live bridge pod found in outpost"
  exit 1
fi

fail=0
for pod in $pods; do
  for field in hostNetwork hostPID hostIPC; do
    value="$(kubectl -n outpost get pod "$pod" -o jsonpath="{.spec.${field}}" 2>/dev/null)"
    if [ "$value" = "true" ]; then
      echo "FAIL: pod ${pod} sets ${field}=true"
      fail=1
    fi
  done
  host_paths="$(kubectl -n outpost get pod "$pod" -o jsonpath='{.spec.volumes[*].hostPath.path}' 2>/dev/null)"
  if [ -n "$host_paths" ]; then
    echo "FAIL: pod ${pod} mounts a hostPath: ${host_paths}"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no host namespace and no hostPath volume"
fi
exit "$fail"
