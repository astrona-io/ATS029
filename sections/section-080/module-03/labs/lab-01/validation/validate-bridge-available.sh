#!/usr/bin/env bash
# Check: behaviour. The bridge Deployment is available with one replica and
# its original container, image and command. Rejects deleting the workload or
# replacing it with another one.
set -uo pipefail

replicas="$(kubectl -n outpost get deployment bridge -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n outpost get deployment bridge -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "$replicas" != "1" ] || [ "${available:-0}" != "1" ]; then
  echo "FAIL: bridge has replicas='${replicas}' and available='${available:-0}', expected 1 and 1"
  exit 1
fi

image="$(kubectl -n outpost get deployment bridge -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
name="$(kubectl -n outpost get deployment bridge -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)"
if [ "$image" != "docker.io/library/busybox:1.37.0" ] || [ "$name" != "bridge" ]; then
  echo "FAIL: the container is '${name}' with image '${image}', expected 'bridge' with the original busybox image"
  exit 1
fi

command_line="$(kubectl -n outpost get deployment bridge -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null)"
case "$command_line" in
  *heartbeat*) ;;
  *) echo "FAIL: the container command no longer writes the heartbeat file"; exit 1 ;;
esac

echo "PASS: bridge is available with its original container"
