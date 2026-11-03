#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The corrected CRD: status subresource, status schema, limits, printer columns.
kubectl apply -f "$DIR/hangar-crd.yaml"
kubectl wait --for=condition=Established crd/hangars.fleet.astrona.io --timeout=60s

# 2. Rule 2 of the ClusterRole is the one for deployments: add the missing verb.
kubectl patch clusterrole hangar-operator --type=json \
  -p '[{"op":"replace","path":"/rules/2/verbs","value":["get","list","watch","create","patch"]}]'

kubectl -n starfleet wait --for=condition=Ready hangar/scout-bay --timeout=240s

# 3. Nothing owns the finalizer legacy.astrona.io/archive, so clear it.
kubectl -n starfleet patch hangar old-bay --type=merge -p '{"metadata":{"finalizers":null}}'
echo "[solution] Applied."
