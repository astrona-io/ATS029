#!/usr/bin/env bash
# Check: behaviour. The rights come from the group bridge-crew: a different
# user name in that group gets them too. Rejects a binding to the single user.
set -uo pipefail

fail=0
expect_yes() {
  local answer
  answer="$(kubectl auth can-i "$1" "$2" -n outpost --as=crew-member --as-group=bridge-crew 2>/dev/null)"
  if [ "$answer" != "yes" ]; then
    echo "FAIL: the group bridge-crew should be allowed to ${1} ${2} in outpost (answer: '${answer}')"
    fail=1
  fi
}

for verb in get list watch create update patch; do
  expect_yes "$verb" deployments.apps
done
for verb in get list watch; do
  expect_yes "$verb" pods
done

if ! kubectl --context ensign-park -n outpost get pods -l app=drifter -o name 2>/dev/null | grep -q '^pod/drifter-'; then
  echo "FAIL: kubectl get pods through the ensign-park context does not list the drifter pod"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the group bridge-crew manages Deployments and reads pods in outpost"
fi
exit "$fail"
