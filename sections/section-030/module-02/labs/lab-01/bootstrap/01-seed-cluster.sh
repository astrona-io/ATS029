#!/usr/bin/env bash
# Starting state for the ResourceQuota lab. Environment only: scout with
# complete resources, shuttle with three replicas and no resources, and no
# ResourceQuota. The learner adds the quota and fixes shuttle.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[lab] Ready."
