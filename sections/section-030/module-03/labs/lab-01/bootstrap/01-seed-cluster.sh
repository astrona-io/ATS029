#!/usr/bin/env bash
# Starting state for the LimitRange lab. Environment only: drifter with no
# resources, beacon that is killed for using more memory than its limit, and
# no LimitRange. The learner fixes it. beacon is not waited for on purpose:
# it does not become ready.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
