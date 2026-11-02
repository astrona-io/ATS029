#!/usr/bin/env bash
set -euo pipefail
expected_context="kind-astro-ats-029-playground-010-01"
if [[ "$(kubectl config current-context)" != "$expected_context" ]]; then
  printf 'Refusing to bootstrap a different Kubernetes context\n' >&2
  exit 1
fi
bootstrap_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$bootstrap_directory/manifests/environment.yaml"
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet wait --for=condition=Ready pod/shuttle --timeout=120s
kubectl -n outpost wait --for=condition=Ready pod/drifter --timeout=120s
kubectl wait --for=condition=Established crd/probesettings.training.astrona.io --timeout=60s
kubectl -n starfleet rollout status deployment/settings-controller --timeout=180s
