#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

openssl genrsa -out "$WORK/ensign-park.key" 2048
openssl req -new -key "$WORK/ensign-park.key" -subj "/CN=ensign-park/O=bridge-crew" -out "$WORK/ensign-park.csr"
REQUEST="$(base64 < "$WORK/ensign-park.csr" | tr -d '\n')"

kubectl apply -f - <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ensign-park
spec:
  request: ${REQUEST}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
YAML

kubectl certificate approve ensign-park

CERT=""
for attempt in $(seq 1 30); do
  CERT="$(kubectl get csr ensign-park -o jsonpath='{.status.certificate}')"
  [ -n "$CERT" ] && break
  sleep 2
done
echo "$CERT" | base64 -d > "$WORK/ensign-park.crt"

CLUSTER="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
kubectl config set-credentials ensign-park \
  --client-key="$WORK/ensign-park.key" \
  --client-certificate="$WORK/ensign-park.crt" \
  --embed-certs=true
kubectl config set-context ensign-park --cluster="$CLUSTER" --user=ensign-park --namespace=outpost

kubectl apply -f - <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: crew-deployer
  namespace: outpost
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bridge-crew-deployer
  namespace: outpost
subjects:
  - kind: Group
    name: bridge-crew
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: crew-deployer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: pinned-images
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.template.spec.containers.all(c, c.image.contains(':') && !c.image.endsWith(':latest'))"
      message: "Container images must use an explicit tag other than latest."
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: pinned-images-outpost
spec:
  policyName: pinned-images
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: outpost
YAML
echo "[solution] Applied."
