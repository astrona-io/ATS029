#!/usr/bin/env bash
# Starting state for the Beacon CRD lab. Environment only: two empty
# namespaces. The learner registers the Beacon type.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/starfleet --timeout=60s
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/outpost --timeout=60s
echo "[lab] Ready."
