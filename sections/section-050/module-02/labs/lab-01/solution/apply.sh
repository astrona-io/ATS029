#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
for name in shuttle scout probe; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[solution] Applied."
