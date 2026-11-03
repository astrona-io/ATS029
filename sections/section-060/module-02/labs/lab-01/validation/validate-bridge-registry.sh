#!/usr/bin/env bash
# Check: bridge-registry is a docker-registry Secret for the right server with
# the right login. Rejects a generic Secret holding the same words.
set -uo pipefail

type="$(kubectl -n starfleet get secret bridge-registry -o jsonpath='{.type}' 2>/dev/null || true)"
if [ "$type" != "kubernetes.io/dockerconfigjson" ]; then
  echo "FAIL: bridge-registry type is '${type}', expected 'kubernetes.io/dockerconfigjson'"
  exit 1
fi

doc="$(kubectl -n starfleet get secret bridge-registry -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode 2>/dev/null || true)"
user="$(printf '%s' "$doc" | jq -r '.auths["registry.starfleet.example"].username' 2>/dev/null || true)"
pass="$(printf '%s' "$doc" | jq -r '.auths["registry.starfleet.example"].password' 2>/dev/null || true)"
if [ "$user" != "fleet-puller" ] || [ "$pass" != "Warp-9000" ]; then
  echo "FAIL: login for registry.starfleet.example is user='${user}' password='${pass}', expected 'fleet-puller' and 'Warp-9000'"
  exit 1
fi

echo "PASS: bridge-registry holds the registry login for registry.starfleet.example"
