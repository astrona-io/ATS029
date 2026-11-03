#!/usr/bin/env bash
# Check: only the password key is mounted, read-only, with mode 0400, at
# /etc/bridge/credentials, and the file holds the rotated value. Rejects a
# mount of every key, a writable mount and the default mode.
set -uo pipefail

spec="$(kubectl -n starfleet get deployment bridge -o json 2>/dev/null || true)"
if [ -z "$spec" ]; then
  echo "FAIL: Deployment bridge not found in starfleet"
  exit 1
fi

volume="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/bridge/credentials") | .name')"
if [ -z "$volume" ]; then
  echo "FAIL: no volume is mounted at /etc/bridge/credentials"
  exit 1
fi

read_only="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/bridge/credentials") | .readOnly // false')"
if [ "$read_only" != "true" ]; then
  echo "FAIL: the mount at /etc/bridge/credentials is not readOnly"
  exit 1
fi

secret_name="$(printf '%s' "$spec" | jq -r --arg v "$volume" '.spec.template.spec.volumes[]? | select(.name==$v) | .secret.secretName // empty')"
if [ "$secret_name" != "bridge-credentials" ]; then
  echo "FAIL: the volume '${volume}' is not the Secret bridge-credentials"
  exit 1
fi

if ! kubectl -n starfleet rollout status deployment/bridge --timeout=150s >/dev/null 2>&1; then
  echo "FAIL: Deployment bridge did not finish rolling out"
  exit 1
fi

files="$(kubectl -n starfleet exec deploy/bridge -- ls /etc/bridge/credentials 2>/dev/null | tr '\n' ' ' | sed 's/ *$//' || true)"
if [ "$files" != "password" ]; then
  echo "FAIL: /etc/bridge/credentials contains '${files}', expected only 'password'"
  exit 1
fi

mode="$(kubectl -n starfleet exec deploy/bridge -- stat -L -c '%a' /etc/bridge/credentials/password 2>/dev/null || true)"
if [ "$mode" != "400" ]; then
  echo "FAIL: /etc/bridge/credentials/password has mode '${mode}', expected 400"
  exit 1
fi

content="$(kubectl -n starfleet exec deploy/bridge -- cat /etc/bridge/credentials/password 2>/dev/null || true)"
if [ "$content" != "Pulsar-2026" ]; then
  echo "FAIL: the mounted password file holds '${content}', expected 'Pulsar-2026'"
  exit 1
fi

echo "PASS: only the password is mounted read-only with mode 0400 and holds the rotated value"
