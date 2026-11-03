#!/usr/bin/env bash
# Check: behaviour. In every running scout pod /etc/scout holds only scout.conf,
# with the two lines of the key and mode 440. Rejects a full-ConfigMap mount and
# a wrong mode.
set -uo pipefail

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase == "Running") | .metadata.name')"
if [ -z "$pods" ]; then
  echo "FAIL: no running scout pod found"
  exit 1
fi

expected_conf="$(printf 'interval=10\ntimeout=2')"
fail=0
for pod in $pods; do
  files="$(kubectl -n starfleet exec "$pod" -c scout -- ls /etc/scout 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
  mode="$(kubectl -n starfleet exec "$pod" -c scout -- stat -L -c '%a' /etc/scout/scout.conf 2>/dev/null || true)"
  content="$(kubectl -n starfleet exec "$pod" -c scout -- cat /etc/scout/scout.conf 2>/dev/null || true)"
  if [ "$files" != "scout.conf" ]; then
    echo "FAIL: pod ${pod}: /etc/scout contains '${files}', expected only scout.conf (select the key with items)"
    fail=1
  fi
  if [ "$mode" != "440" ]; then
    echo "FAIL: pod ${pod}: /etc/scout/scout.conf has mode '${mode}', expected 440"
    fail=1
  fi
  if [ "$content" != "$expected_conf" ]; then
    echo "FAIL: pod ${pod}: /etc/scout/scout.conf does not hold the two lines 'interval=10' and 'timeout=2'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running scout pod has only /etc/scout/scout.conf with mode 440"
fi
exit "$fail"
