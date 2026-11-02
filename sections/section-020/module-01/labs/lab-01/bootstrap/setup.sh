#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-029-lab-020-01-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
bootstrap_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$bootstrap_directory/manifests/start.yaml"
if [[ "$(kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:shuttle || true)" != "no" ]]; then
  printf 'Starting identity unexpectedly has Pod access\n' >&2
  exit 1
fi
