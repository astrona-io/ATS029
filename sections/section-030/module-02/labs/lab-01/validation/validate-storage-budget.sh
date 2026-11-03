#!/usr/bin/env bash
# Check: behaviour. The PersistentVolumeClaim logbook exists with 2Gi and
# ReadWriteOnce, a second 2Gi claim is refused with "exceeded quota", and a
# 1Gi claim still fits. Both extra claims are server-side dry runs.
set -uo pipefail

fail=0

size="$(kubectl -n starfleet get pvc logbook -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)"
mode="$(kubectl -n starfleet get pvc logbook -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null || true)"
if [ "$size" != "2Gi" ]; then
  echo "FAIL: PersistentVolumeClaim logbook requests '${size}', expected 2Gi"
  fail=1
fi
if [ "$mode" != "ReadWriteOnce" ]; then
  echo "FAIL: PersistentVolumeClaim logbook access mode is '${mode}', expected ReadWriteOnce"
  fail=1
fi

big_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grader-big
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
YAML
)"
big_status=$?
if [ "$big_status" -eq 0 ] || ! echo "$big_output" | grep -q 'exceeded quota'; then
  echo "FAIL: a second 2Gi claim was not rejected with 'exceeded quota': ${big_output}"
  fail=1
fi

small_output="$(kubectl apply --request-timeout=30s --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grader-small
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
YAML
)"
small_status=$?
if [ "$small_status" -ne 0 ]; then
  echo "FAIL: a 1Gi claim that fits the storage budget was rejected: ${small_output}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: logbook exists and the storage quota rejects a second large claim"
fi
exit "$fail"
