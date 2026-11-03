#!/usr/bin/env bash
# Check: behaviour. Every running probe pod has SETTING_LOG_LEVEL and
# SETTING_REGION from probe-settings, and the template has envFrom with the
# prefix SETTING_. Rejects a missing prefix and pods that were never replaced.
set -uo pipefail

prefix="$(kubectl -n starfleet get deployment probe -o json 2>/dev/null \
  | jq -r '[.spec.template.spec.containers[] | select(.name == "probe") | .envFrom[]? | select(.configMapRef.name == "probe-settings") | .prefix // ""] | first // "none"')"
if [ "$prefix" != "SETTING_" ]; then
  echo "FAIL: the probe container needs an envFrom entry for probe-settings with prefix SETTING_ (found '${prefix}')"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null \
  | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase == "Running") | .metadata.name')"
if [ -z "$pods" ]; then
  echo "FAIL: no running probe pod found"
  exit 1
fi

fail=0
for pod in $pods; do
  region="$(kubectl -n starfleet exec "$pod" -c probe -- printenv SETTING_REGION 2>/dev/null || true)"
  level="$(kubectl -n starfleet exec "$pod" -c probe -- printenv SETTING_LOG_LEVEL 2>/dev/null || true)"
  if [ "$region" != "outpost-7" ] || [ "$level" != "debug" ]; then
    echo "FAIL: pod ${pod} has SETTING_REGION='${region}' and SETTING_LOG_LEVEL='${level}', expected 'outpost-7' and 'debug'"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running probe pod has the SETTING_ variables from probe-settings"
fi
exit "$fail"
