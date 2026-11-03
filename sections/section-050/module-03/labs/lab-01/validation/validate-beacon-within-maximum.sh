#!/usr/bin/env bash
# Check: beacon is Running with limits inside the LimitRange maximums and a
# request that is not above the limit. Rejects deleting beacon or leaving the
# CPU limit at 2.
set -uo pipefail

fail=0
NS=outpost

if ! kubectl -n $NS get deployment beacon >/dev/null 2>&1; then
  echo "FAIL: the beacon Deployment was deleted; change its resources instead"
  exit 1
fi

res="$(kubectl -n $NS get deployment beacon -o json | jq -c '.spec.template.spec.containers[0].resources')"
cpu_limit="$(echo "$res" | jq -r '.limits.cpu // empty')"
mem_limit="$(echo "$res" | jq -r '.limits.memory // empty')"
cpu_request="$(echo "$res" | jq -r '.requests.cpu // empty')"
mem_request="$(echo "$res" | jq -r '.requests.memory // empty')"

to_millis() {
  case "$1" in
    *m) echo "${1%m}" ;;
    ''|*[!0-9.]*) ;;
    *) awk -v v="$1" 'BEGIN { printf "%d", v * 1000 }' ;;
  esac
}
to_mib() {
  case "$1" in
    *Gi) echo $(( ${1%Gi} * 1024 )) ;;
    *Mi) echo "${1%Mi}" ;;
    *) ;;
  esac
}

cpu_limit_m="$(to_millis "$cpu_limit")"
cpu_request_m="$(to_millis "$cpu_request")"
mem_limit_mib="$(to_mib "$mem_limit")"
mem_request_mib="$(to_mib "$mem_request")"

if [ -z "$cpu_limit_m" ] || [ "$cpu_limit_m" -gt 500 ] || [ "$cpu_limit_m" -lt 1 ]; then
  echo "FAIL: the beacon CPU limit must be at most 500m (found: '${cpu_limit}')"
  fail=1
fi
if [ -z "$mem_limit_mib" ] || [ "$mem_limit_mib" -gt 256 ]; then
  echo "FAIL: the beacon memory limit must be at most 256Mi (found: '${mem_limit}')"
  fail=1
fi
if [ -z "$cpu_request_m" ] || { [ -n "$cpu_limit_m" ] && [ "$cpu_request_m" -gt "$cpu_limit_m" ]; }; then
  echo "FAIL: the beacon CPU request is missing or above its limit"
  fail=1
fi
if [ -z "$mem_request_mib" ] || { [ -n "$mem_limit_mib" ] && [ "$mem_request_mib" -gt "$mem_limit_mib" ]; }; then
  echo "FAIL: the beacon memory request is missing or above its limit"
  fail=1
fi

if ! kubectl -n $NS rollout status deployment/beacon --timeout=90s >/dev/null 2>&1; then
  echo "FAIL: the beacon Deployment is not fully rolled out"
  fail=1
fi
phase="$(kubectl -n $NS get pods -l app=beacon -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp==null) | .status.phase] | join(",")')"
if [ "$phase" != "Running" ]; then
  echo "FAIL: the beacon Pod phase is '${phase}', expected Running"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon runs with limits of ${cpu_limit} CPU and ${mem_limit} memory"
fi
exit "$fail"
