#!/usr/bin/env bash
# Check: the Deployments keep their images and replica counts. Only the
# resources may change.
set -uo pipefail

fail=0
NS=starfleet

check_image() {
  local deployment="$1" expected="$2" actual
  actual="$(kubectl -n $NS get deployment "$deployment" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $deployment image is '${actual}', expected '${expected}'"
    fail=1
  fi
  replicas="$(kubectl -n $NS get deployment "$deployment" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
  if [ "$replicas" != "1" ]; then
    echo "FAIL: $deployment has ${replicas:-no} replicas, expected 1"
    fail=1
  fi
}

check_image shuttle busybox:1.37.0
check_image scout ghcr.io/stefanprodan/podinfo:6.15.0
check_image probe busybox:1.37.0

sidecar="$(kubectl -n $NS get deployment scout -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="metrics-agent")].restartPolicy}' 2>/dev/null || true)"
if [ "$sidecar" != "Always" ]; then
  echo "FAIL: the scout metrics-agent sidecar must stay (restartPolicy Always)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: images, replicas and the sidecar are unchanged"
fi
exit "$fail"
