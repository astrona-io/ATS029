#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl wait --for=condition=Established crd/beacons.signals.astrona.io --timeout=60s
kubectl apply -f "$DIR/beacon.yaml"
echo "[solution] Applied."
