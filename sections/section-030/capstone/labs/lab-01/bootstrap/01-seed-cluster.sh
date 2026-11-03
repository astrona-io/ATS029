#!/usr/bin/env bash
# Starting state for the capstone. Environment only: probe with no resources,
# bridge that is killed for using more memory than its limit, no LimitRange and
# no ResourceQuota. The learner fixes it. bridge is not waited for on purpose:
# it does not become ready.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[lab] Ready."
