#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-029-lab-010-01-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
lab_directory="$(cd "$(dirname "$0")/.." && pwd)"
solution_directory="$lab_directory/solution"
cluster_name="astro-ats-029-lab-010-01-01"

kubectl apply -f "$solution_directory/probesetting-greeting.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.ready}'=true probesetting/greeting --timeout=120s
