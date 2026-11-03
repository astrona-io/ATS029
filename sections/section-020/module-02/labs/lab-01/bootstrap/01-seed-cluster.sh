#!/usr/bin/env bash
# Starting state for the CertificateSigningRequest lab. Environment only: two
# namespaces with a Deployment each. The learner creates the user.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
