#!/usr/bin/env bash
# Check: behaviour. Every live shuttle pod has no privileged container, blocks
# privilege escalation and holds no capability. Rejects the plausible wrong
# fixes: only removing privileged, or dropping capabilities from one container.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=shuttle --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live shuttle pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  for container in shuttle relay; do
    privileged="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.privileged}" 2>/dev/null)"
    escalation="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.allowPrivilegeEscalation}" 2>/dev/null)"
    drop="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.capabilities.drop}" 2>/dev/null)"
    add="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.capabilities.add}" 2>/dev/null)"
    if [ "$privileged" = "true" ]; then
      echo "FAIL: container ${container} in ${pod} is still privileged"
      fail=1
    fi
    if [ "$escalation" != "false" ]; then
      echo "FAIL: container ${container} in ${pod} has allowPrivilegeEscalation='${escalation}', expected false"
      fail=1
    fi
    case "$drop" in
      *ALL*) ;;
      *) echo "FAIL: container ${container} in ${pod} does not drop ALL capabilities"; fail=1 ;;
    esac
    if [ -n "$add" ]; then
      echo "FAIL: container ${container} in ${pod} adds capabilities: ${add}"
      fail=1
    fi
    mask="$(timeout 20 kubectl -n starfleet exec "$pod" -c "$container" -- grep CapEff /proc/1/status 2>/dev/null | awk '{print $2}')"
    if [ "$mask" != "0000000000000000" ]; then
      echo "FAIL: container ${container} in ${pod} has effective capabilities '${mask}', expected all zeros"
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no privileged container, no escalation, no capabilities"
fi
exit "$fail"
