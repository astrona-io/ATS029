#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

openssl genrsa -out "$WORK/ensign-lee.key" 2048
openssl req -new -key "$WORK/ensign-lee.key" -subj "/CN=ensign-lee" -out "$WORK/ensign-lee.csr"
REQUEST="$(base64 < "$WORK/ensign-lee.csr" | tr -d '\n')"

kubectl apply -f - <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ensign-lee
spec:
  request: ${REQUEST}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
YAML

kubectl certificate approve ensign-lee

for attempt in $(seq 1 30); do
  CERT="$(kubectl get csr ensign-lee -o jsonpath='{.status.certificate}')"
  [ -n "$CERT" ] && break
  sleep 2
done
echo "$CERT" | base64 -d > "$WORK/ensign-lee.crt"

CLUSTER="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
kubectl config set-credentials ensign-lee \
  --client-key="$WORK/ensign-lee.key" \
  --client-certificate="$WORK/ensign-lee.crt" \
  --embed-certs=true
kubectl config set-context ensign-lee --cluster="$CLUSTER" --user=ensign-lee --namespace=outpost

kubectl -n outpost create role pod-viewer --verb=get,list,watch --resource=pods
kubectl -n outpost create rolebinding ensign-lee-pod-viewer --role=pod-viewer --user=ensign-lee
echo "[solution] Applied."
