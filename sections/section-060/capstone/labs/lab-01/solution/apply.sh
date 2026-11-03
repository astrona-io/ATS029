#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet patch secret bridge-credentials -p '{"stringData":{"password":"Pulsar-2026"}}'

kubectl -n starfleet create secret docker-registry bridge-registry \
  --docker-server=registry.starfleet.example \
  --docker-username=fleet-puller \
  --docker-password='Warp-9000'

kubectl apply -f "$DIR/bridge-deployment.yaml"
kubectl -n starfleet rollout status deployment/bridge --timeout=180s
echo "[solution] Applied."
