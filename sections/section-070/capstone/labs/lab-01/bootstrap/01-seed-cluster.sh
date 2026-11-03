#!/usr/bin/env bash
# Starting state for the ServiceAccounts capstone. Environment only: bridge and
# scout on the default service account, which is bound to cluster-admin. The
# learner fixes it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in scout bridge; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
