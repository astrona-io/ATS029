#!/usr/bin/env bash
# Check: the CertificateSigningRequest ensign-lee is approved and the issued
# certificate belongs to ensign-lee. Rejects a CSR that is only created, one
# for another signer, and a certificate for another subject.
set -uo pipefail

if ! kubectl get csr ensign-lee >/dev/null 2>&1; then
  echo "FAIL: CertificateSigningRequest ensign-lee does not exist"
  exit 1
fi

signer="$(kubectl get csr ensign-lee -o jsonpath='{.spec.signerName}')"
if [ "$signer" != "kubernetes.io/kube-apiserver-client" ]; then
  echo "FAIL: signerName is '${signer}', expected kubernetes.io/kube-apiserver-client"
  exit 1
fi

approved="$(kubectl get csr ensign-lee -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}')"
if [ "$approved" != "True" ]; then
  echo "FAIL: the CertificateSigningRequest is not approved"
  exit 1
fi

cert="$(kubectl get csr ensign-lee -o jsonpath='{.status.certificate}')"
if [ -z "$cert" ]; then
  echo "FAIL: no certificate was issued yet"
  exit 1
fi

subject="$(echo "$cert" | base64 -d | openssl x509 -noout -subject 2>/dev/null)"
if ! echo "$subject" | grep -Eq 'CN ?= ?ensign-lee($|,|/)'; then
  echo "FAIL: the certificate subject is '${subject}', expected CN=ensign-lee"
  exit 1
fi

echo "PASS: the CSR is approved and the certificate is issued for ensign-lee"
