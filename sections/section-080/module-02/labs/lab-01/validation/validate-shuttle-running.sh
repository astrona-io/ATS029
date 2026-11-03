#!/usr/bin/env bash
# Check: behaviour. The Deployment is available with its original images and
# replica count, and shuttle keeps writing the heartbeat file. Rejects scaling
# to zero or replacing the workload.
set -uo pipefail

replicas="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "$replicas" != "1" ] || [ "${available:-0}" != "1" ]; then
  echo "FAIL: shuttle has replicas='${replicas}' and available='${available:-0}', expected 1 and 1"
  exit 1
fi

images="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{range .spec.template.spec.containers[*]}{.name}={.image}{" "}{end}' 2>/dev/null)"
if [ "$images" != "shuttle=docker.io/library/busybox:1.37.0 relay=docker.io/library/busybox:1.37.0 " ]; then
  echo "FAIL: container names or images changed: ${images}"
  exit 1
fi

pod="$(kubectl -n starfleet get pods -l app=shuttle --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1; exit}')"
modified="$(timeout 20 kubectl -n starfleet exec "$pod" -c relay -- stat -c '%Y' /data/heartbeat 2>/dev/null)"
now="$(timeout 20 kubectl -n starfleet exec "$pod" -c relay -- date +%s 2>/dev/null)"
if [ -z "$modified" ] || [ -z "$now" ] || [ $((now - modified)) -gt 30 ]; then
  echo "FAIL: /data/heartbeat is missing or has not been updated in the last 30 seconds"
  exit 1
fi

echo "PASS: shuttle is available and keeps writing /data/heartbeat"
