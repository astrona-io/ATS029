#!/usr/bin/env bash
# Check: behaviour. Both running containers hold no capability, cannot gain
# privilege, run with a seccomp filter and have a read-only root filesystem,
# and the application still writes /tmp/state. Rejects privileged containers
# and a fix that drops readOnlyRootFilesystem.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=probe --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live probe pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  for container in probe logger; do
    privileged="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.privileged}" 2>/dev/null)"
    read_only="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.readOnlyRootFilesystem}" 2>/dev/null)"
    add="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.containers[?(@.name=='${container}')].securityContext.capabilities.add}" 2>/dev/null)"
    if [ "$privileged" = "true" ]; then
      echo "FAIL: container ${container} in ${pod} is privileged"
      fail=1
    fi
    if [ "$read_only" != "true" ]; then
      echo "FAIL: container ${container} in ${pod} has readOnlyRootFilesystem='${read_only}', expected true"
      fail=1
    fi
    if [ -n "$add" ]; then
      echo "FAIL: container ${container} in ${pod} adds capabilities: ${add}"
      fail=1
    fi
    status="$(timeout 20 kubectl -n starfleet exec "$pod" -c "$container" -- cat /proc/1/status 2>/dev/null)"
    seccomp="$(echo "$status" | awk '$1=="Seccomp:"{print $2}')"
    mask="$(echo "$status" | awk '$1=="CapEff:"{print $2}')"
    no_new_privs="$(echo "$status" | awk '$1=="NoNewPrivs:"{print $2}')"
    if [ "$seccomp" != "2" ]; then
      echo "FAIL: seccomp mode of ${container} in ${pod} is '${seccomp}', expected 2"
      fail=1
    fi
    if [ "$mask" != "0000000000000000" ]; then
      echo "FAIL: ${container} in ${pod} has effective capabilities '${mask}', expected all zeros"
      fail=1
    fi
    if [ "$no_new_privs" != "1" ]; then
      echo "FAIL: NoNewPrivs of ${container} in ${pod} is '${no_new_privs}', expected 1"
      fail=1
    fi
    if timeout 20 kubectl -n starfleet exec "$pod" -c "$container" -- touch /rootfs-check >/dev/null 2>&1; then
      echo "FAIL: a write to the root filesystem succeeded in ${container} of ${pod}"
      fail=1
    fi
  done
  state="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- cat /tmp/state 2>/dev/null)"
  if [ "$state" != "up" ]; then
    echo "FAIL: /tmp/state contains '${state}', expected 'up'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no capability, no escalation, seccomp filter and read-only root filesystem"
fi
exit "$fail"
