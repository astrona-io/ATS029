#!/usr/bin/env bash
# Check: behaviour. The running bridge process has a seccomp filter, runs as
# user 1000, holds no capability and cannot gain privilege. Rejects a fix that
# sets the fields on only one level or runs as root.
set -uo pipefail

pods="$(kubectl -n outpost get pods -l app=bridge --no-headers \
  -o custom-columns=NAME:.metadata.name,DEL:.metadata.deletionTimestamp 2>/dev/null | awk '$2=="<none>"{print $1}')"
if [ -z "$pods" ]; then
  echo "FAIL: no live bridge pod found in outpost"
  exit 1
fi

fail=0
for pod in $pods; do
  uid="$(timeout 20 kubectl -n outpost exec "$pod" -c bridge -- id -u 2>/dev/null)"
  if [ "$uid" != "1000" ]; then
    echo "FAIL: bridge runs as user '${uid}', expected 1000"
    fail=1
  fi
  status="$(timeout 20 kubectl -n outpost exec "$pod" -c bridge -- cat /proc/1/status 2>/dev/null)"
  seccomp="$(echo "$status" | awk '$1=="Seccomp:"{print $2}')"
  mask="$(echo "$status" | awk '$1=="CapEff:"{print $2}')"
  no_new_privs="$(echo "$status" | awk '$1=="NoNewPrivs:"{print $2}')"
  if [ "$seccomp" != "2" ]; then
    echo "FAIL: the seccomp mode of bridge is '${seccomp}', expected 2 (filter active)"
    fail=1
  fi
  if [ "$mask" != "0000000000000000" ]; then
    echo "FAIL: bridge has effective capabilities '${mask}', expected all zeros"
    fail=1
  fi
  if [ "$no_new_privs" != "1" ]; then
    echo "FAIL: NoNewPrivs of bridge is '${no_new_privs}', expected 1"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: bridge runs as 1000 with a seccomp filter, no capability and no privilege escalation"
fi
exit "$fail"
