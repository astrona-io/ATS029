#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"

kubectl -n starfleet set resources deployment shuttle \
  --requests=cpu=200m,memory=128Mi --limits=cpu=400m,memory=256Mi
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[solution] Applied."
