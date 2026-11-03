#!/usr/bin/env bash
# Check: the bridge account lists regcred, and every running bridge pod uses the
# account and received regcred. A pod that was not recreated after the account
# change has no imagePullSecrets and fails here.
set -uo pipefail

listed="$(kubectl -n starfleet get serviceaccount bridge -o jsonpath='{.imagePullSecrets[*].name}' 2>/dev/null || true)"
case " $listed " in
  *" regcred "*) ;;
  *)
    echo "FAIL: ServiceAccount bridge does not list regcred in imagePullSecrets (found: '${listed}')"
    exit 1
    ;;
esac

pods="$(kubectl -n starfleet get pods -l app=bridge -o json 2>/dev/null | jq -c '[.items[] | select(.metadata.deletionTimestamp == null)]')"
count="$(echo "$pods" | jq 'length')"
if [ -z "$count" ] || [ "$count" -lt 1 ]; then
  echo "FAIL: no running bridge pods found"
  exit 1
fi

fail=0
for index in $(seq 0 $((count - 1))); do
  name="$(echo "$pods" | jq -r ".[$index].metadata.name")"
  account="$(echo "$pods" | jq -r ".[$index].spec.serviceAccountName")"
  has_secret="$(echo "$pods" | jq -r ".[$index].spec.imagePullSecrets // [] | map(select(.name == \"regcred\")) | length")"
  if [ "$account" != "bridge" ]; then
    echo "FAIL: pod $name uses account '${account}', expected bridge"
    fail=1
  fi
  if [ "$has_secret" != "1" ]; then
    echo "FAIL: pod $name does not have regcred in imagePullSecrets (roll the Deployment after changing the account)"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: bridge account lists regcred and bridge pods received it"
fi
exit "$fail"
