#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"

# drifter: restart so the new pod passes through the LimitRange defaults.
kubectl -n outpost rollout restart deployment/drifter
kubectl -n outpost rollout status deployment/drifter --timeout=180s

# beacon: requests equal limits for CPU and memory, memory above its real use.
kubectl -n outpost set resources deployment beacon \
  --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n outpost rollout status deployment/beacon --timeout=180s
echo "[solution] Applied."
