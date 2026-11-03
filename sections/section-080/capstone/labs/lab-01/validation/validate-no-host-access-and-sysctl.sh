#!/usr/bin/env bash
# Check: behaviour. No live probe pod uses a host namespace or a hostPath
# volume, and the pod sets the safe sysctl net.ipv4.ip_local_port_range to
# "32768 40000", which the container also reads from the kernel.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=probe --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live probe pod found in starfleet"
  exit 1
fi

fail=0
for pod in $pods; do
  for field in hostNetwork hostPID hostIPC; do
    value="$(kubectl -n starfleet get pod "$pod" -o jsonpath="{.spec.${field}}" 2>/dev/null)"
    if [ "$value" = "true" ]; then
      echo "FAIL: pod ${pod} sets ${field}=true"
      fail=1
    fi
  done
  host_paths="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.volumes[*].hostPath.path}' 2>/dev/null)"
  if [ -n "$host_paths" ]; then
    echo "FAIL: pod ${pod} mounts a hostPath: ${host_paths}"
    fail=1
  fi
  sysctl_value="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.securityContext.sysctls[?(@.name=="net.ipv4.ip_local_port_range")].value}' 2>/dev/null)"
  if [ "$sysctl_value" != "32768 40000" ]; then
    echo "FAIL: pod ${pod} sets net.ipv4.ip_local_port_range to '${sysctl_value}', expected '32768 40000'"
    fail=1
  fi
  runtime_value="$(timeout 20 kubectl -n starfleet exec "$pod" -c probe -- cat /proc/sys/net/ipv4/ip_local_port_range 2>/dev/null | tr -s '[:space:]' ' ' | sed 's/ $//')"
  if [ "$runtime_value" != "32768 40000" ]; then
    echo "FAIL: the kernel value in ${pod} is '${runtime_value}', expected '32768 40000'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no host access and the safe sysctl is set"
fi
exit "$fail"
