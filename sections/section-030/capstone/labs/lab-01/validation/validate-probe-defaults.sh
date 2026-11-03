#!/usr/bin/env bash
# Check: probe is available, its live pod carries the LimitRange defaults,
# and the Deployment template itself still declares no resources. The last
# test catches a learner who typed the values into the Deployment instead of
# letting the LimitRange supply them.
set -uo pipefail

fail=0

available="$(kubectl -n starfleet get deployment probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
if [ "${available:-0}" != "3" ]; then
  echo "FAIL: Deployment probe has ${available:-0} of 3 replicas available"
  fail=1
fi

template_resources="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].resources}' 2>/dev/null || true)"
if [ -n "$template_resources" ] && [ "$template_resources" != "{}" ]; then
  echo "FAIL: the probe Deployment template declares resources ($template_resources); the defaults must come from the LimitRange"
  fail=1
fi

pods_json="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null)"
live="$(echo "$pods_json" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
wrong="$(echo "$pods_json" | jq -r '
  .items[]
  | select(.metadata.deletionTimestamp == null)
  | .metadata.name as $name
  | .spec.containers[0].resources as $r
  | select(($r.requests.cpu // "") != "100m"
        or ($r.requests.memory // "") != "128Mi"
        or ($r.limits.cpu // "") != "200m"
        or ($r.limits.memory // "") != "256Mi")
  | $name')"
if [ "${live:-0}" -ne 3 ]; then
  echo "FAIL: expected 3 live probe pods"
  fail=1
fi
if [ -n "$wrong" ]; then
  echo "FAIL: these probe pods do not carry the default requests (100m, 128Mi) and limits (200m, 256Mi):"
  echo "$wrong" | sed 's/^/  /'
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe pods carry the LimitRange defaults and the template declares nothing"
fi
exit "$fail"
