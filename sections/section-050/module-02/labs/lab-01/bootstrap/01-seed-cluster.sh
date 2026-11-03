#!/usr/bin/env bash
# Starting state for the resources lab. Environment only: it creates the
# workloads with their faults. It does not fix anything.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[lab] Ready. shuttle is failing and probe is Pending on purpose."
