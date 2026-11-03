#!/usr/bin/env bash
# Check: the kubeconfig has a context ensign-lee with embedded credentials and
# the API server authenticates it as ensign-lee.
set -uo pipefail

if ! kubectl config get-contexts -o name 2>/dev/null | grep -qx 'ensign-lee'; then
  echo "FAIL: no kubeconfig context named ensign-lee"
  exit 1
fi

embedded="$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="ensign-lee")].user.client-certificate-data}' 2>/dev/null)"
key_embedded="$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="ensign-lee")].user.client-key-data}' 2>/dev/null)"
if [ -z "$embedded" ] || [ -z "$key_embedded" ]; then
  echo "FAIL: the credentials ensign-lee do not embed the certificate and key (use --embed-certs=true)"
  exit 1
fi

namespace="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="ensign-lee")].context.namespace}' 2>/dev/null)"
if [ "$namespace" != "outpost" ]; then
  echo "FAIL: the context ensign-lee has namespace '${namespace}', expected outpost"
  exit 1
fi

name="$(kubectl --context ensign-lee auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)"
if [ "$name" != "ensign-lee" ]; then
  echo "FAIL: the API server reports the user '${name}' for the context ensign-lee, expected ensign-lee"
  exit 1
fi

echo "PASS: the context ensign-lee authenticates as ensign-lee"
