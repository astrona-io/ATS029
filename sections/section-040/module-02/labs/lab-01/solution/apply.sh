#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

printf 'MODE=fast\nRETRIES=3\n' > "$WORK/scout.env"
kubectl -n starfleet create configmap scout-env --from-env-file="$WORK/scout.env"

printf 'retries=3\nregion=outpost-7\n' > "$WORK/scout.properties"
printf 'scout online\n' > "$WORK/banner.txt"
kubectl -n starfleet create configmap scout-files \
  --from-file=app.properties="$WORK/scout.properties" \
  --from-file="$WORK/banner.txt"

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-locked
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: warn
YAML

kubectl -n starfleet patch configmap probe-settings -p '{"data":{"LOG_LEVEL":"info"}}'
echo "[solution] Applied."
