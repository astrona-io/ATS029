#!/usr/bin/env bash
# Check: behaviour. The processes run with the requested numeric identity:
# user 1500 and group 3000 in shuttle, user 2500 in relay (container-level
# override). Rejects setting the same user in both containers or using only
# container-level fields.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=shuttle --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live shuttle pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  pod_user="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)"
  pod_group="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.securityContext.runAsGroup}' 2>/dev/null)"
  if [ "$pod_user" != "1500" ] || [ "$pod_group" != "3000" ]; then
    echo "FAIL: pod-level runAsUser='${pod_user}' runAsGroup='${pod_group}', expected 1500 and 3000"
    fail=1
  fi
  relay_user="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='relay')].securityContext.runAsUser}" 2>/dev/null)"
  if [ "$relay_user" != "2500" ]; then
    echo "FAIL: container relay has runAsUser='${relay_user}', expected 2500"
    fail=1
  fi
  shuttle_uid="$(timeout 20 kubectl -n starfleet exec "$pod" -c shuttle -- id -u 2>/dev/null)"
  shuttle_gid="$(timeout 20 kubectl -n starfleet exec "$pod" -c shuttle -- id -g 2>/dev/null)"
  relay_uid="$(timeout 20 kubectl -n starfleet exec "$pod" -c relay -- id -u 2>/dev/null)"
  relay_gid="$(timeout 20 kubectl -n starfleet exec "$pod" -c relay -- id -g 2>/dev/null)"
  if [ "$shuttle_uid" != "1500" ] || [ "$shuttle_gid" != "3000" ]; then
    echo "FAIL: shuttle runs as ${shuttle_uid}:${shuttle_gid}, expected 1500:3000"
    fail=1
  fi
  if [ "$relay_uid" != "2500" ] || [ "$relay_gid" != "3000" ]; then
    echo "FAIL: relay runs as ${relay_uid}:${relay_gid}, expected 2500:3000"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle runs as 1500:3000 and relay as 2500:3000"
fi
exit "$fail"
