#!/usr/bin/env bash
# Starting state for the ConfigMaps capstone. Environment only: the scout
# Deployment without any configuration. The learner builds everything else.
# UNTESTED: authored with static checks only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[lab] Ready."
