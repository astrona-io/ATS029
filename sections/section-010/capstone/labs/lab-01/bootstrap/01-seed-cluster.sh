#!/usr/bin/env bash
# Starting state for the capstone. Environment only: a Hangar CRD without a status
# subresource, schema rules or printer columns, an operator whose ClusterRole
# lacks `create` on deployments, the Hangar scout-bay that cannot reconcile, and
# the Hangar old-bay that is marked for deletion but held by a finalizer.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl wait --for=condition=Established crd/hangars.fleet.astrona.io --timeout=120s
kubectl -n fleet-system rollout status deployment/hangar-operator --timeout=240s

kubectl apply -f "$DIR/manifests/hangars.yaml"
kubectl -n starfleet delete hangar old-bay --wait=false

# The grader uses this to detect a Hangar that was deleted and created again.
scout_uid="$(kubectl -n starfleet get hangar scout-bay -o jsonpath='{.metadata.uid}')"
kubectl -n fleet-system create configmap lab-baseline --from-literal=scout-bay-uid="$scout_uid"
echo "[lab] Ready."
