#!/usr/bin/env bash
# Check: probe has a CPU request in millicores (below one core), is Ready, and
# was not made schedulable by removing the request.
set -uo pipefail

fail=0
NS=starfleet

cpu_request="$(kubectl -n $NS get deployment probe -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)"
cpu_limit="$(kubectl -n $NS get deployment probe -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)"

case "$cpu_request" in
  *m) millis="${cpu_request%m}" ;;
  '') millis="" ;;
  *) millis="" ;;
esac
if [ -z "$cpu_request" ]; then
  echo "FAIL: probe has no CPU request"
  fail=1
elif [ -z "$millis" ] || ! [ "$millis" -ge 1 ] 2>/dev/null || [ "$millis" -ge 1000 ]; then
  echo "FAIL: the probe CPU request must be written in millicores below 1000m (found: ${cpu_request})"
  fail=1
fi

case "$cpu_limit" in
  *m) limit_millis="${cpu_limit%m}" ;;
  *) limit_millis="" ;;
esac
if [ -n "$millis" ] && [ -n "$limit_millis" ] && [ "$millis" -gt "$limit_millis" ] 2>/dev/null; then
  echo "FAIL: the probe CPU request is above its limit"
  fail=1
fi
if [ -z "$limit_millis" ]; then
  echo "FAIL: the probe CPU limit must be written in millicores (found: '${cpu_limit}')"
  fail=1
fi

if ! kubectl -n $NS rollout status deployment/probe --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the probe Deployment did not finish rolling out"
  fail=1
fi

phase="$(kubectl -n $NS get pods -l app=probe -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp==null) | .status.phase] | join(",")')"
case "$phase" in
  Running) ;;
  *) echo "FAIL: the probe Pod phase is '${phase}', expected Running"; fail=1 ;;
esac

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe requests ${cpu_request} of CPU and is Running"
fi
exit "$fail"
