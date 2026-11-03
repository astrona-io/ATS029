#!/usr/bin/env bash
# Check: shuttle has a memory limit between 192Mi and 512Mi, a request not
# above the limit, and a running Pod that was not killed for memory.
# Rejects the plausible wrong fixes: raising only the request, removing the
# limit, or setting an absurdly large limit.
set -uo pipefail

fail=0
NS=starfleet

limit="$(kubectl -n $NS get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)"
request="$(kubectl -n $NS get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)"

to_mib() {
  # Converts a Kubernetes memory quantity to whole MiB. Prints nothing if unknown.
  case "$1" in
    *Gi) echo $(( ${1%Gi} * 1024 )) ;;
    *Mi) echo "${1%Mi}" ;;
    *Ki) echo $(( ${1%Ki} / 1024 )) ;;
    *G) echo $(( ${1%G} * 953 )) ;;
    *M) echo $(( ${1%M} * 953 / 1000 )) ;;
    ''|*[!0-9]*) ;;
    *) echo $(( $1 / 1048576 )) ;;
  esac
}

limit_mib="$(to_mib "$limit")"
request_mib="$(to_mib "$request")"

if [ -z "$limit_mib" ]; then
  echo "FAIL: shuttle has no usable memory limit (found: '${limit}')"
  fail=1
elif [ "$limit_mib" -lt 192 ] || [ "$limit_mib" -gt 512 ]; then
  echo "FAIL: the shuttle memory limit must be between 192Mi and 512Mi (found: ${limit})"
  fail=1
fi
if [ -z "$request_mib" ]; then
  echo "FAIL: shuttle has no memory request"
  fail=1
elif [ -n "$limit_mib" ] && [ "$request_mib" -gt "$limit_mib" ]; then
  echo "FAIL: the shuttle memory request is above its limit"
  fail=1
fi

if ! kubectl -n $NS rollout status deployment/shuttle --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment did not finish rolling out"
  fail=1
fi

# Let the process finish its memory peak before reading the status.
sleep 20
pods="$(kubectl -n $NS get pods -l app=shuttle -o json 2>/dev/null)"
running="$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running")] | length')"
killed="$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp==null) | .status.containerStatuses[]? | select(.lastState.terminated.reason=="OOMKilled" or .state.terminated.reason=="OOMKilled")] | length')"
if [ "${running:-0}" -lt 1 ]; then
  echo "FAIL: no shuttle Pod is Running"
  fail=1
fi
if [ "${killed:-0}" -gt 0 ]; then
  echo "FAIL: a shuttle container was killed for memory (OOMKilled)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle has a memory limit of ${limit} and runs without memory kills"
fi
exit "$fail"
