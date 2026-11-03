#!/usr/bin/env bash
# Starting state for the Secrets capstone. Environment only: a Secret with an
# old password, a bridge Deployment with the same password as a plain value,
# and an auditor service account without permissions. The learner fixes it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/bridge --timeout=180s
echo "[lab] Ready."
