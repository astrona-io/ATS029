#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl apply -f - <<YAML
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: outpost
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 50m
        memory: 32Mi
      default:
        cpu: 200m
        memory: 64Mi
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.replicas <= 3"
      message: "A Deployment may not have more than 3 replicas."
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-outpost
spec:
  policyName: replica-limit
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: outpost
YAML
echo "[solution] Applied."
