#!/usr/bin/env bash
# Check: behaviour. Through the ensign-park context, an untagged or latest image
# is rejected by a ValidatingAdmissionPolicy (not by RBAC) and a pinned tag is
# accepted. The policy does not apply in starfleet. Retries because a new
# binding takes a few seconds to become active.
set -uo pipefail

if ! kubectl config get-contexts -o name 2>/dev/null | grep -qx 'ensign-park'; then
  echo "FAIL: no kubeconfig context named ensign-park"
  exit 1
fi

create_as_user() {
  # $1 image
  kubectl --context ensign-park -n outpost create deployment image-check \
    --image="$1" --dry-run=server 2>&1
}

output=""
status=0
for attempt in $(seq 1 15); do
  output="$(create_as_user busybox:latest)"
  status=$?
  [ "$status" -ne 0 ] && break
  sleep 2
done

if [ "$status" -eq 0 ]; then
  echo "FAIL: a Deployment with the image busybox:latest is accepted in outpost"
  exit 1
fi
if ! echo "$output" | grep -q 'ValidatingAdmissionPolicy'; then
  echo "FAIL: the request was rejected, but not by a ValidatingAdmissionPolicy: ${output}"
  exit 1
fi

output="$(create_as_user busybox)"
if [ $? -eq 0 ]; then
  echo "FAIL: a Deployment with an image without a tag is accepted in outpost"
  exit 1
fi

output="$(create_as_user busybox:1.37.0)"
if [ $? -ne 0 ]; then
  echo "FAIL: a Deployment with the pinned image busybox:1.37.0 is rejected: ${output}"
  exit 1
fi

update_output="$(kubectl -n outpost set image deployment/drifter drifter=busybox:latest --dry-run=server 2>&1)"
if [ $? -eq 0 ]; then
  echo "FAIL: changing drifter to busybox:latest is accepted; the policy must cover UPDATE"
  exit 1
fi

if ! kubectl -n starfleet create deployment image-check --image=busybox:latest --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: busybox:latest is rejected in starfleet; the binding must select only outpost"
  exit 1
fi

echo "PASS: unpinned images are rejected by the policy in outpost and only there"
