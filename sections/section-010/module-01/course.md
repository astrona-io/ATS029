---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Custom Types And Application Reconciliation

This module connects intended application behavior to declared resources and observed conditions.

## Learning Goals

- Distinguish type registration from controller behavior.
- Read scope, versions and schema of a custom type.
- Interpret desired fields and controller observations.
- Explain prerequisite, permission and finalizer failures.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. Custom Resources And Operators
2. Reading A Custom Resource And Its Controller Contract
3. Create A Custom Resource And Observe Its Controller
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
