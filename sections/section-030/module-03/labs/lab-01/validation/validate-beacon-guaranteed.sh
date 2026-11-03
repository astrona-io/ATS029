#!/usr/bin/env bash
# Check: behaviour. beacon has one replica, available, its live pod is
# Guaranteed, and the container is no longer killed. The script waits 20
# seconds first, because beacon allocates its memory a moment after start and
# an unfixed limit only shows as a restart after that.
set -uo pipefail

fail=0

desired="$(kubectl -n outpost get deployment beacon -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [ "$desired" != "1" ]; then
  echo "FAIL: Deployment beacon has ${desired:-no} replicas configured, expected 1"
  exit 1
fi

sleep 20

pods_json="$(kubectl -n outpost get pods -l app=beacon -o json 2>/dev/null)"
live="$(echo "$pods_json" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "${live:-0}" != "1" ]; then
  echo "FAIL: expected exactly 1 live beacon pod, found ${live:-0}"
  exit 1
fi

pod="$(echo "$pods_json" | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)][0]')"
qos="$(echo "$pod" | jq -r '.status.qosClass // ""')"
phase="$(echo "$pod" | jq -r '.status.phase // ""')"
restarts="$(echo "$pod" | jq -r '.status.containerStatuses[0].restartCount // 0')"
running="$(echo "$pod" | jq -r '.status.containerStatuses[0].state.running != null')"
last_reason="$(echo "$pod" | jq -r '.status.containerStatuses[0].lastState.terminated.reason // ""')"
memory_limit="$(echo "$pod" | jq -r '.spec.containers[0].resources.limits.memory // ""')"

if [ "$qos" != "Guaranteed" ]; then
  echo "FAIL: the beacon pod has QoS class '${qos}', expected Guaranteed (requests must equal limits for CPU and memory)"
  fail=1
fi
if [ "$phase" != "Running" ] || [ "$running" != "true" ]; then
  echo "FAIL: the beacon pod is not running (phase '${phase}')"
  fail=1
fi
if [ "$restarts" != "0" ] || [ "$last_reason" = "OOMKilled" ]; then
  echo "FAIL: the beacon container restarted ${restarts} times (last reason '${last_reason}'); its memory limit '${memory_limit}' is too small"
  fail=1
fi
case "$memory_limit" in
  *Gi) fail=1; echo "FAIL: the beacon memory limit '${memory_limit}' is above the LimitRange maximum" ;;
esac

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon is Guaranteed, running and not restarting"
fi
exit "$fail"
