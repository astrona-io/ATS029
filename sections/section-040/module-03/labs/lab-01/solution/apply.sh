#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

# A JSON patch replaces the env list as a whole, so the fixed value is removed.
kubectl -n starfleet patch deployment probe --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/env", "value": [
    {"name": "LOG_LEVEL", "valueFrom": {"configMapKeyRef": {"name": "probe-settings", "key": "LOG_LEVEL"}}}
  ]},
  {"op": "add", "path": "/spec/template/spec/containers/0/envFrom", "value": [
    {"prefix": "SETTING_", "configMapRef": {"name": "probe-settings"}}
  ]},
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [
    {"name": "settings", "mountPath": "/etc/probe", "readOnly": true}
  ]},
  {"op": "add", "path": "/spec/template/spec/volumes", "value": [
    {"name": "settings", "configMap": {"name": "probe-settings", "items": [
      {"key": "probe.properties", "path": "probe.conf", "mode": 292}
    ]}}
  ]}
]'

kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[solution] Applied."
