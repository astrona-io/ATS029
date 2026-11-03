#!/usr/bin/env bash
# Check: behaviour. ensign-lee reads pods in outpost through the new context.
set -uo pipefail

for verb in get list watch; do
  answer="$(kubectl --context ensign-lee -n outpost auth can-i "$verb" pods 2>/dev/null)"
  if [ "$answer" != "yes" ]; then
    echo "FAIL: ensign-lee cannot ${verb} pods in outpost (answer: '${answer}')"
    exit 1
  fi
done

if ! kubectl --context ensign-lee -n outpost get pods -l app=drifter -o name 2>/dev/null | grep -q '^pod/drifter-'; then
  echo "FAIL: kubectl get pods through the ensign-lee context does not list the drifter pod"
  exit 1
fi

echo "PASS: ensign-lee lists the drifter pod in outpost"
