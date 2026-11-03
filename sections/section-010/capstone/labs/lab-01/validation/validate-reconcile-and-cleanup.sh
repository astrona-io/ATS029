#!/usr/bin/env bash
# Check: behaviour. Creates a temporary Hangar and proves the whole loop: the
# operator creates an owned Deployment, applies a scale change, and the
# garbage collector removes the Deployment after the Hangar is deleted.
set -uo pipefail

name="grader-bay"
deployment="hangar-${name}"

cleanup() {
  kubectl -n starfleet delete hangar "$name" --ignore-not-found --wait=false >/dev/null 2>&1
  kubectl -n starfleet delete deployment "$deployment" --ignore-not-found --wait=false >/dev/null 2>&1
}
trap cleanup EXIT

wait_for() {
  # wait_for <seconds> <command...>: run the command every 3 seconds until it succeeds.
  local seconds="$1"
  shift
  local waited=0
  while [ "$waited" -lt "$seconds" ]; do
    if "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
    waited=$((waited + 3))
  done
  return 1
}

deployment_has_owner() {
  local uid
  uid="$(kubectl -n starfleet get hangar "$name" -o jsonpath='{.metadata.uid}' 2>/dev/null)" || return 1
  kubectl -n starfleet get deployment "$deployment" -o json 2>/dev/null \
    | jq -e --arg uid "$uid" '.metadata.ownerReferences[]? | select(.kind == "Hangar" and .uid == $uid)'
}

deployment_has_replicas() {
  [ "$(kubectl -n starfleet get deployment "$deployment" -o jsonpath='{.spec.replicas}' 2>/dev/null)" = "$1" ]
}

status_current() {
  local json
  json="$(kubectl -n starfleet get hangar "$name" -o json 2>/dev/null)" || return 1
  echo "$json" | jq -e '(.status.observedGeneration // -1) == .metadata.generation and ([.status.conditions[]? | select(.type == "Ready")] | length) == 1'
}

deployment_gone() {
  ! kubectl -n starfleet get deployment "$deployment" >/dev/null 2>&1
}

# A leftover from an earlier run must not disturb the check.
cleanup
wait_for 60 deployment_gone || true

if ! printf 'apiVersion: fleet.astrona.io/v1\nkind: Hangar\nmetadata:\n  name: %s\n  namespace: starfleet\nspec:\n  replicas: 1\n' "$name" \
  | kubectl create -f - >/dev/null 2>&1; then
  echo "FAIL: could not create a test Hangar; is the Hangar CRD still installed?"
  exit 1
fi

if ! wait_for 90 deployment_has_owner; then
  echo "FAIL: the operator did not create an owned Deployment ${deployment} within 90 seconds"
  exit 1
fi

kubectl -n starfleet patch hangar "$name" --type=merge -p '{"spec":{"replicas":2}}' >/dev/null 2>&1
if ! wait_for 90 deployment_has_replicas 2; then
  echo "FAIL: the operator did not apply a change of spec.replicas to the Deployment"
  exit 1
fi

if ! wait_for 60 status_current; then
  echo "FAIL: the status of ${name} does not follow its generation; is the status subresource enabled?"
  exit 1
fi

kubectl -n starfleet delete hangar "$name" --wait=false >/dev/null 2>&1
if ! wait_for 90 deployment_gone; then
  echo "FAIL: the Deployment ${deployment} was not removed after the Hangar was deleted"
  exit 1
fi

echo "PASS: a new Hangar is reconciled, scaled and cleaned up"
exit 0
