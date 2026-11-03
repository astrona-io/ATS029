#!/usr/bin/env bash
# Starting state for the ServiceAccount creation lab. Environment only: the
# Starfleet workloads running as the default service account, and the regcred
# Secret. The learner creates the service accounts.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
