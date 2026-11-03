#!/usr/bin/env bash
# Check: behaviour. The shared volume belongs to group 4000 (fsGroup) and the
# files written in it get that group. Rejects a fix that only chmods the volume
# or sets the group on a container.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=shuttle --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live shuttle pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  fs_group="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.securityContext.fsGroup}' 2>/dev/null)"
  if [ "$fs_group" != "4000" ]; then
    echo "FAIL: pod-level fsGroup is '${fs_group}', expected 4000"
    fail=1
  fi
  dir_group="$(timeout 20 kubectl -n starfleet exec "$pod" -c shuttle -- stat -c '%g' /data 2>/dev/null)"
  if [ "$dir_group" != "4000" ]; then
    echo "FAIL: /data has group '${dir_group}', expected 4000"
    fail=1
  fi
  file_owner="$(timeout 20 kubectl -n starfleet exec "$pod" -c relay -- stat -c '%u:%g' /data/heartbeat 2>/dev/null)"
  if [ "$file_owner" != "1500:4000" ]; then
    echo "FAIL: /data/heartbeat is owned by '${file_owner}', expected 1500:4000"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: /data belongs to group 4000 and new files inherit it"
fi
exit "$fail"
