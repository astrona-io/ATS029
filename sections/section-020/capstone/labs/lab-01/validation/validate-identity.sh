#!/usr/bin/env bash
# Check: the CSR is approved and issued for CN=ensign-park with O=bridge-crew,
# and the kubeconfig context authenticates as ensign-park in bridge-crew.
set -uo pipefail

if ! kubectl get csr ensign-park >/dev/null 2>&1; then
  echo "FAIL: CertificateSigningRequest ensign-park does not exist"
  exit 1
fi

signer="$(kubectl get csr ensign-park -o jsonpath='{.spec.signerName}')"
if [ "$signer" != "kubernetes.io/kube-apiserver-client" ]; then
  echo "FAIL: signerName is '${signer}', expected kubernetes.io/kube-apiserver-client"
  exit 1
fi

approved="$(kubectl get csr ensign-park -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}')"
cert="$(kubectl get csr ensign-park -o jsonpath='{.status.certificate}')"
if [ "$approved" != "True" ] || [ -z "$cert" ]; then
  echo "FAIL: the CertificateSigningRequest is not approved and issued"
  exit 1
fi

subject="$(echo "$cert" | base64 -d | openssl x509 -noout -subject 2>/dev/null)"
if ! echo "$subject" | grep -Eq 'CN ?= ?ensign-park($|,|/)'; then
  echo "FAIL: the certificate subject is '${subject}', expected CN=ensign-park"
  exit 1
fi
if ! echo "$subject" | grep -Eq 'O ?= ?bridge-crew($|,|/)'; then
  echo "FAIL: the certificate subject is '${subject}', expected O=bridge-crew"
  exit 1
fi

if ! kubectl config get-contexts -o name 2>/dev/null | grep -qx 'ensign-park'; then
  echo "FAIL: no kubeconfig context named ensign-park"
  exit 1
fi
cert_data="$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="ensign-park")].user.client-certificate-data}' 2>/dev/null)"
key_data="$(kubectl config view --raw -o jsonpath='{.users[?(@.name=="ensign-park")].user.client-key-data}' 2>/dev/null)"
if [ -z "$cert_data" ] || [ -z "$key_data" ]; then
  echo "FAIL: the credentials ensign-park do not embed the certificate and key (use --embed-certs=true)"
  exit 1
fi
namespace="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="ensign-park")].context.namespace}' 2>/dev/null)"
if [ "$namespace" != "outpost" ]; then
  echo "FAIL: the context ensign-park has namespace '${namespace}', expected outpost"
  exit 1
fi

name="$(kubectl --context ensign-park auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)"
if [ "$name" != "ensign-park" ]; then
  echo "FAIL: the API server reports the user '${name}' for the context ensign-park"
  exit 1
fi
groups="$(kubectl --context ensign-park auth whoami -o jsonpath='{.status.userInfo.groups}' 2>/dev/null)"
if ! echo "$groups" | grep -q 'bridge-crew'; then
  echo "FAIL: ensign-park is not in the group bridge-crew (groups: ${groups})"
  exit 1
fi

echo "PASS: ensign-park authenticates through the certificate in the group bridge-crew"
