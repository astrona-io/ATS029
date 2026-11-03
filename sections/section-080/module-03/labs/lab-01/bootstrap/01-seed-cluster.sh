#!/usr/bin/env bash
# Starting state for the Pod Security Admission lab. Environment only: the
# `outpost` namespace enforcing restricted and a `bridge` Deployment whose pod
# template the namespace rejects. The learner fixes the template.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

# The Deployment is accepted and its ReplicaSet is created, but no pod exists.
for _ in $(seq 1 30); do
  if [ -n "$(kubectl -n outpost get replicaset -l app=bridge -o name 2>/dev/null)" ]; then
    break
  fi
  sleep 2
done
echo "[lab] Ready."
