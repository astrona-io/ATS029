#!/usr/bin/env bash
# Starting state for the namespace policy lab. Environment only: it creates the
# namespace, the quota and the faulty Deployments. It creates no LimitRange.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n outpost rollout status deployment/beacon --timeout=180s
echo "[lab] Ready. drifter has no Pods yet because the quota refuses them."
