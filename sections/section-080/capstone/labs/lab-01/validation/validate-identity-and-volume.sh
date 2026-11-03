#!/usr/bin/env bash
# Check: behaviour. The processes run with the requested identity (probe
# 3000:3000, logger 3500:3000), the shared volume belongs to group 4000 and the
# files written in it get that group.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=probe --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live probe pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  probe_uid="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- id -u 2>/dev/null)"
  probe_gid="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- id -g 2>/dev/null)"
  logger_uid="$(timeout 20 kubectl -n starfleet exec "$pod" -c logger -- id -u 2>/dev/null)"
  logger_gid="$(timeout 20 kubectl -n starfleet exec "$pod" -c logger -- id -g 2>/dev/null)"
  if [ "$probe_uid" != "3000" ] || [ "$probe_gid" != "3000" ]; then
    echo "FAIL: probe runs as ${probe_uid}:${probe_gid}, expected 3000:3000"
    fail=1
  fi
  if [ "$logger_uid" != "3500" ] || [ "$logger_gid" != "3000" ]; then
    echo "FAIL: logger runs as ${logger_uid}:${logger_gid}, expected 3500:3000"
    fail=1
  fi
  fs_group="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.securityContext.fsGroup}' 2>/dev/null)"
  if [ "$fs_group" != "4000" ]; then
    echo "FAIL: pod-level fsGroup is '${fs_group}', expected 4000"
    fail=1
  fi
  dir_group="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- stat -c '%g' /shared 2>/dev/null)"
  if [ "$dir_group" != "4000" ]; then
    echo "FAIL: /shared has group '${dir_group}', expected 4000"
    fail=1
  fi
  heartbeat_owner="$(timeout 20 kubectl -n starfleet exec "$pod" -c logger -- stat -c '%u:%g' /shared/heartbeat 2>/dev/null)"
  seen_owner="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- stat -c '%u:%g' /shared/logger-seen 2>/dev/null)"
  if [ "$heartbeat_owner" != "3000:4000" ]; then
    echo "FAIL: /shared/heartbeat is owned by '${heartbeat_owner}', expected 3000:4000"
    fail=1
  fi
  if [ "$seen_owner" != "3500:4000" ]; then
    echo "FAIL: /shared/logger-seen is owned by '${seen_owner}', expected 3500:4000"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: identity, group 4000 on /shared and file ownership are correct"
fi
exit "$fail"
