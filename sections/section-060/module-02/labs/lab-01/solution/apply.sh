#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet create secret generic scout-credentials \
  --from-literal=api-key=ion-4471

env_file="$(mktemp)"
printf 'REGION=outpost-4\nTIER=gold\n' > "$env_file"
kubectl -n starfleet create secret generic bridge-settings --from-env-file="$env_file"
rm -f "$env_file"

kubectl -n starfleet create secret docker-registry bridge-registry \
  --docker-server=registry.starfleet.example \
  --docker-username=fleet-puller \
  --docker-password='Warp-9000'

kubectl -n starfleet patch secret scout-credentials -p '{"immutable":true}'

kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[solution] Applied."
