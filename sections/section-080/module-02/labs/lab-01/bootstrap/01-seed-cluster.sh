#!/usr/bin/env bash
# Starting state for the identity and privilege lab. Environment only: the
# `shuttle` Deployment with a privileged container, running as root. The
# learner fixes it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[lab] Ready."
