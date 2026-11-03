#!/usr/bin/env bash
# Check: bridge-credentials has the rotated password and keeps its username,
# and bridge-registry is a docker-registry Secret with the right login.
# Rejects a recreated Secret that lost the username and a generic registry
# Secret.
set -uo pipefail

password="$(kubectl -n starfleet get secret bridge-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode 2>/dev/null; echo x)"
password="${password%x}"
if [ "$password" != "Pulsar-2026" ]; then
  echo "FAIL: the password in bridge-credentials is not exactly 'Pulsar-2026'"
  exit 1
fi

username="$(kubectl -n starfleet get secret bridge-credentials -o jsonpath='{.data.username}' 2>/dev/null | base64 --decode 2>/dev/null || true)"
if [ "$username" != "bridge-operator" ]; then
  echo "FAIL: the username in bridge-credentials is '${username}', expected 'bridge-operator'"
  exit 1
fi

type="$(kubectl -n starfleet get secret bridge-registry -o jsonpath='{.type}' 2>/dev/null || true)"
if [ "$type" != "kubernetes.io/dockerconfigjson" ]; then
  echo "FAIL: bridge-registry type is '${type}', expected 'kubernetes.io/dockerconfigjson'"
  exit 1
fi

doc="$(kubectl -n starfleet get secret bridge-registry -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode 2>/dev/null || true)"
user="$(printf '%s' "$doc" | jq -r '.auths["registry.starfleet.example"].username' 2>/dev/null || true)"
pass="$(printf '%s' "$doc" | jq -r '.auths["registry.starfleet.example"].password' 2>/dev/null || true)"
if [ "$user" != "fleet-puller" ] || [ "$pass" != "Warp-9000" ]; then
  echo "FAIL: the registry login for registry.starfleet.example is wrong (user='${user}')"
  exit 1
fi

echo "PASS: bridge-credentials is rotated and bridge-registry holds the right login"
