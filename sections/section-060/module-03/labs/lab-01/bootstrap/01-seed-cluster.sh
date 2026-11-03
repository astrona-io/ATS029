#!/usr/bin/env bash
# Starting state for the Secret consumption lab. Environment only: two Secrets,
# two service accounts and a probe Deployment that holds its password as a
# plain value. The learner fixes it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[lab] Ready."
