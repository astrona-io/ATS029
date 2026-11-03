#!/usr/bin/env bash
# Starting state for the capstone. Environment only: it creates the namespace,
# the quota and the faulty Deployments. It creates no LimitRange.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
sleep 5
echo "[lab] Ready. bridge restarts, scout and shuttle have no Pods yet, on purpose."
