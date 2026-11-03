#!/usr/bin/env bash
# Check: the pod template uses scout-config-v2 everywhere (configMapKeyRef,
# envFrom with prefix SCOUT_, one configMap volume) and never scout-config-v1
# or subPath.
set -uo pipefail

if ! json="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null)"; then
  echo "FAIL: the Deployment scout does not exist in starfleet"
  exit 1
fi

template="$(echo "$json" | jq -c '.spec.template.spec')"

if echo "$template" | grep -q 'scout-config-v1'; then
  echo "FAIL: the pod template still refers to scout-config-v1; the change must use scout-config-v2 only"
  exit 1
fi

key_ref="$(echo "$template" | jq -r '[.containers[] | select(.name == "scout") | .env[]? | select(.name == "LOG_LEVEL") | .valueFrom.configMapKeyRef | "\(.name)/\(.key)"] | first // "none"')"
if [ "$key_ref" != "scout-config-v2/LOG_LEVEL" ]; then
  echo "FAIL: the variable LOG_LEVEL must use configMapKeyRef scout-config-v2 key LOG_LEVEL (found '${key_ref}')"
  exit 1
fi

prefix="$(echo "$template" | jq -r '[.containers[] | select(.name == "scout") | .envFrom[]? | select(.configMapRef.name == "scout-config-v2") | .prefix // ""] | first // "none"')"
if [ "$prefix" != "SCOUT_" ]; then
  echo "FAIL: the scout container needs envFrom for scout-config-v2 with prefix SCOUT_ (found '${prefix}')"
  exit 1
fi

volume="$(echo "$template" | jq -r '[.volumes[]? | select(.configMap.name == "scout-config-v2")] | length')"
if [ "$volume" != "1" ]; then
  echo "FAIL: the pod needs exactly one configMap volume for scout-config-v2 (found ${volume})"
  exit 1
fi

subpaths="$(echo "$template" | jq -r '[.containers[].volumeMounts[]? | select(.subPath != null)] | length')"
if [ "$subpaths" != "0" ]; then
  echo "FAIL: a volume mount uses subPath; it would never receive updates"
  exit 1
fi

echo "PASS: the pod template uses scout-config-v2 for the variable, envFrom and the volume"
