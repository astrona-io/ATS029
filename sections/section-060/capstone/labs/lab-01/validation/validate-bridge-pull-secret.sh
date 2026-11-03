#!/usr/bin/env bash
# Check: the running bridge pods carry bridge-registry as an image pull Secret
# (set on the pod template or through the service account) and are ready.
# Rejects a Secret that exists but is not referenced.
set -uo pipefail

if ! kubectl -n starfleet rollout status deployment/bridge --timeout=150s >/dev/null 2>&1; then
  echo "FAIL: Deployment bridge did not finish rolling out"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=bridge -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)"
if [ -z "$pods" ]; then
  echo "FAIL: no bridge pod found"
  exit 1
fi

for pod in $pods; do
  names="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.imagePullSecrets[*].name}' 2>/dev/null || true)"
  case " $names " in
    *" bridge-registry "*) ;;
    *)
      echo "FAIL: pod ${pod} does not list bridge-registry in imagePullSecrets (found '${names}')"
      exit 1
      ;;
  esac
done

echo "PASS: every bridge pod references bridge-registry for image pulls"
