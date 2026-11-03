#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-config-v1
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: info
  REGION: outpost-7
  scout.conf: |
    interval=10
    timeout=2
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-config-v2
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: debug
  REGION: outpost-7
  scout.conf: |
    interval=10
    timeout=2
YAML

kubectl -n starfleet patch deployment scout --type=json -p '[
  {"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [
    {"name": "LOG_LEVEL", "valueFrom": {"configMapKeyRef": {"name": "scout-config-v2", "key": "LOG_LEVEL"}}}
  ]},
  {"op": "add", "path": "/spec/template/spec/containers/0/envFrom", "value": [
    {"prefix": "SCOUT_", "configMapRef": {"name": "scout-config-v2"}}
  ]},
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [
    {"name": "config", "mountPath": "/etc/scout", "readOnly": true}
  ]},
  {"op": "add", "path": "/spec/template/spec/volumes", "value": [
    {"name": "config", "configMap": {"name": "scout-config-v2", "items": [
      {"key": "scout.conf", "path": "scout.conf", "mode": 288}
    ]}}
  ]}
]'

kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[solution] Applied."
