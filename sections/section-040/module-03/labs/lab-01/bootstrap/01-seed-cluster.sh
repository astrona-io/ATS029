#!/usr/bin/env bash
# Starting state for the "Consume ConfigMaps In A Deployment" lab. Environment
# only: the probe-settings ConfigMap and the probe Deployment with a fixed
# LOG_LEVEL. The learner wires the ConfigMap in. UNTESTED: static checks only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[lab] Ready."
