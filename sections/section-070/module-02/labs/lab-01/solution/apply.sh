#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet set serviceaccount deployment scout scout
kubectl -n starfleet set serviceaccount deployment probe probe

for workload in scout probe; do
  kubectl -n starfleet rollout status "deployment/${workload}" --timeout=180s
done
echo "[solution] Applied."
