#!/usr/bin/env bash
# Check: behaviour. More than 3 replicas is rejected in outpost by a
# ValidatingAdmissionPolicy, on create and on update. A binding with only Warn
# or Audit, and a policy without UPDATE, both fail here. The check retries
# because a new binding takes a few seconds to become active.
set -uo pipefail

try_create() {
  # $1 replicas. Prints the error text; returns the kubectl exit code.
  kubectl -n outpost create deployment replica-check --image=busybox:1.37.0 \
    --replicas="$1" --dry-run=server 2>&1
}

output=""
for attempt in $(seq 1 15); do
  output="$(try_create 5)"
  status=$?
  [ "$status" -ne 0 ] && break
  sleep 2
done

if [ "$status" -eq 0 ]; then
  echo "FAIL: a Deployment with 5 replicas is accepted in outpost"
  exit 1
fi
if ! echo "$output" | grep -q 'ValidatingAdmissionPolicy'; then
  echo "FAIL: the request was rejected, but not by a ValidatingAdmissionPolicy: ${output}"
  exit 1
fi

output="$(try_create 4)"
if [ $? -eq 0 ]; then
  echo "FAIL: a Deployment with 4 replicas is accepted; the limit is 3"
  exit 1
fi

update_output="$(kubectl -n outpost patch deployment drifter --type=merge \
  -p '{"spec":{"replicas":5}}' --dry-run=server 2>&1)"
if [ $? -eq 0 ]; then
  echo "FAIL: changing drifter to 5 replicas is accepted; the policy must cover UPDATE"
  exit 1
fi
if ! echo "$update_output" | grep -q 'ValidatingAdmissionPolicy'; then
  echo "FAIL: the update was rejected, but not by a ValidatingAdmissionPolicy: ${update_output}"
  exit 1
fi

echo "PASS: more than 3 replicas is rejected on create and on update"
