#!/usr/bin/env bash
# Starting state for the ServiceAccount tokens lab. Environment only: the
# Starfleet workloads running as the default service account. The learner
# creates the account, the Role and the RoleBinding.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
