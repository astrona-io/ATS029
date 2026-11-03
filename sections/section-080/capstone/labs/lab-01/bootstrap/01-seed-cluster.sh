#!/usr/bin/env bash
# Starting state for the capstone. Environment only: the `starfleet` namespace
# enforcing restricted and a `probe` Deployment whose pod template the
# namespace rejects. The learner fixes the template.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

# The Deployment is accepted and its ReplicaSet is created, but no pod exists.
for _ in $(seq 1 30); do
  if [ -n "$(kubectl -n starfleet get replicaset -l app=probe -o name 2>/dev/null)" ]; then
    break
  fi
  sleep 2
done
echo "[lab] Ready."
