#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# LimitRange first, then the quota, so new pods always receive requests.
kubectl apply -f "$DIR/solution.yaml"

# probe: restart so the new pods pass through the defaults and the quota.
kubectl -n starfleet rollout restart deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=180s

# bridge: requests equal limits, memory above its real use.
kubectl -n starfleet set resources deployment bridge \
  --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n starfleet rollout status deployment/bridge --timeout=180s
echo "[solution] Applied."
