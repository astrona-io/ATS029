#!/usr/bin/env bash
# Starting state for the "Creating ConfigMaps" lab. Environment only: the
# starfleet namespace and the probe-settings ConfigMap. The learner creates
# the other ConfigMaps. UNTESTED: authored with static checks only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet get configmap probe-settings >/dev/null
echo "[lab] Ready."
