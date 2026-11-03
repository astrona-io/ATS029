#!/usr/bin/env bash
# Starting state for the Secret creation lab. Environment only: a scout
# Deployment whose pod waits for a Secret that does not exist yet. The learner
# creates the Secrets.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

# The pod cannot start without the Secret, so wait for the pod object only.
for _ in $(seq 1 60); do
  if kubectl -n starfleet get pods -l app=scout -o name 2>/dev/null | grep -q pod/; then
    break
  fi
  sleep 2
done
echo "[lab] Ready."
