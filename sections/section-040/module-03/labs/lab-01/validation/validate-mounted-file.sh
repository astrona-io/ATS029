#!/usr/bin/env bash
# Check: behaviour. Every running probe pod has /etc/probe/probe.conf with the
# content of the key probe.properties, mode 444, and no other file in the
# directory. Rejects subPath, a full-ConfigMap mount and a wrong mode.
set -uo pipefail

json="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null || true)"
if [ -z "$json" ]; then
  echo "FAIL: the Deployment probe does not exist in starfleet"
  exit 1
fi

subpaths="$(echo "$json" | jq -r '[.spec.template.spec.containers[].volumeMounts[]? | select(.subPath != null)] | length')"
if [ "$subpaths" != "0" ]; then
  echo "FAIL: a volume mount uses subPath; a subPath file never receives updates of the ConfigMap"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase == "Running") | .metadata.name')"
if [ -z "$pods" ]; then
  echo "FAIL: no running probe pod found"
  exit 1
fi

fail=0
for pod in $pods; do
  content="$(kubectl -n starfleet exec "$pod" -c probe -- cat /etc/probe/probe.conf 2>/dev/null || true)"
  mode="$(kubectl -n starfleet exec "$pod" -c probe -- stat -L -c '%a' /etc/probe/probe.conf 2>/dev/null || true)"
  files="$(kubectl -n starfleet exec "$pod" -c probe -- ls /etc/probe 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$content" != "retries=3" ]; then
    echo "FAIL: pod ${pod}: /etc/probe/probe.conf is missing or has the content '${content}', expected 'retries=3'"
    fail=1
  fi
  if [ "$mode" != "444" ]; then
    echo "FAIL: pod ${pod}: /etc/probe/probe.conf has mode '${mode}', expected 444"
    fail=1
  fi
  if [ "$files" != "1" ]; then
    echo "FAIL: pod ${pod}: /etc/probe has ${files} files, expected only probe.conf (select the key with items)"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running probe pod has only /etc/probe/probe.conf with mode 444"
fi
exit "$fail"
