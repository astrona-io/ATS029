---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Identity And API Access Decisions

A caller can have a valid identity and still be forbidden to read Pods. It can also be allowed to create Pods while admission rejects a privileged configuration. Identity, permission and accepted configuration are distinct decisions.

## Learning Goals

- Distinguish authentication, authorization and admission.
- Explain workload identity in API requests.
- Evaluate role scope and additive grants.
- Diagnose denial at the correct access-control stage.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. API Request Checks And Workload Identity
2. RBAC Grants And Their Consequences
3. Grant One Namespace Permission And Verify A Denial
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
