#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n outpost set resources deployment beacon -c beacon --requests=cpu=100m,memory=64Mi --limits=cpu=400m,memory=128Mi
kubectl -n outpost rollout status deployment/beacon --timeout=180s
kubectl -n outpost rollout restart deployment/drifter
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[solution] Applied."
