#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet rollout restart deployment/shuttle
for name in bridge scout shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[solution] Applied."
