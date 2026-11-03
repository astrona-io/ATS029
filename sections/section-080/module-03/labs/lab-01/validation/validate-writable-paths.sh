#!/usr/bin/env bash
# Check: behaviour. The root filesystem is read-only, and the application still
# writes /tmp/state and /work/heartbeat on volumes. Rejects a fix that drops
# readOnlyRootFilesystem to make the application start.
set -uo pipefail

pods="$(kubectl -n outpost get pods -l app=bridge --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live bridge pod found in outpost"
  exit 1
fi

fail=0
for pod in $pods; do
  read_only="$(kubectl -n outpost get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='bridge')].securityContext.readOnlyRootFilesystem}" 2>/dev/null)"
  if [ "$read_only" != "true" ]; then
    echo "FAIL: readOnlyRootFilesystem is '${read_only}', expected true"
    fail=1
  fi
  if timeout 20 kubectl -n outpost exec "$pod" -c bridge -- touch /rootfs-check >/dev/null 2>&1; then
    echo "FAIL: a write to the root filesystem succeeded in ${pod}"
    fail=1
  fi
  state="$(timeout 20 kubectl -n outpost exec "$pod" -c bridge -- cat /tmp/state 2>/dev/null)"
  if [ "$state" != "up" ]; then
    echo "FAIL: /tmp/state contains '${state}', expected 'up'"
    fail=1
  fi
  modified="$(timeout 20 kubectl -n outpost exec "$pod" -c bridge -- stat -c '%Y' /work/heartbeat 2>/dev/null)"
  now="$(timeout 20 kubectl -n outpost exec "$pod" -c bridge -- date +%s 2>/dev/null)"
  if [ -z "$modified" ] || [ -z "$now" ] || [ $((now - modified)) -gt 30 ]; then
    echo "FAIL: /work/heartbeat is missing or older than 30 seconds in ${pod}"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: root filesystem is read-only and the application writes /tmp and /work"
fi
exit "$fail"
