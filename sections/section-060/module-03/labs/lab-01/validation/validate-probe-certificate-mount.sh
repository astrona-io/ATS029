#!/usr/bin/env bash
# Check: probe-certificate is mounted read-only at /etc/probe/tls with mode
# 0400. Rejects the default mode 0644, a writable mount and a copy of the
# values into a ConfigMap.
set -uo pipefail

spec="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null || true)"
if [ -z "$spec" ]; then
  echo "FAIL: Deployment probe not found in starfleet"
  exit 1
fi

volume="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/probe/tls") | .name')"
if [ -z "$volume" ]; then
  echo "FAIL: no volume is mounted at /etc/probe/tls"
  exit 1
fi

read_only="$(printf '%s' "$spec" | jq -r '.spec.template.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/probe/tls") | .readOnly // false')"
if [ "$read_only" != "true" ]; then
  echo "FAIL: the mount at /etc/probe/tls is not readOnly"
  exit 1
fi

secret_name="$(printf '%s' "$spec" | jq -r --arg v "$volume" '.spec.template.spec.volumes[]? | select(.name==$v) | .secret.secretName // empty')"
if [ "$secret_name" != "probe-certificate" ]; then
  echo "FAIL: the volume '${volume}' is not the Secret probe-certificate (found '${secret_name}')"
  exit 1
fi

if ! kubectl -n starfleet rollout status deployment/probe --timeout=150s >/dev/null 2>&1; then
  echo "FAIL: Deployment probe did not finish rolling out"
  exit 1
fi

for file in tls.crt tls.key; do
  mode="$(kubectl -n starfleet exec deploy/probe -- stat -L -c '%a' "/etc/probe/tls/${file}" 2>/dev/null || true)"
  if [ "$mode" != "400" ]; then
    echo "FAIL: /etc/probe/tls/${file} has mode '${mode}', expected 400"
    exit 1
  fi
done

echo "PASS: probe-certificate is mounted read-only with mode 0400"
