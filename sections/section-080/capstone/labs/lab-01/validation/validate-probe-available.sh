#!/usr/bin/env bash
# Check: behaviour. The probe Deployment is available with one replica and its
# original containers, images and commands.
set -uo pipefail

replicas="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n starfleet get deployment probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "$replicas" != "1" ] || [ "${available:-0}" != "1" ]; then
  echo "FAIL: probe has replicas='${replicas}' and available='${available:-0}', expected 1 and 1"
  exit 1
fi

images="$(kubectl -n starfleet get deployment probe -o jsonpath='{range .spec.template.spec.containers[*]}{.name}={.image}{" "}{end}' 2>/dev/null)"
if [ "$images" != "probe=docker.io/library/busybox:1.37.0 logger=docker.io/library/busybox:1.37.0 " ]; then
  echo "FAIL: container names or images changed: ${images}"
  exit 1
fi

commands="$(kubectl -n starfleet get deployment probe -o jsonpath='{range .spec.template.spec.containers[*]}{.command}{" "}{end}' 2>/dev/null)"
case "$commands" in
  *heartbeat*logger-seen*) ;;
  *) echo "FAIL: the container commands changed"; exit 1 ;;
esac

echo "PASS: probe is available with its original containers"
