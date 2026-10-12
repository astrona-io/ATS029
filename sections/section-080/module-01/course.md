---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Security Contexts And Application Privilege

An application runs as a non-root user but still needs a writable temporary directory. Making its root filesystem read-only does not create that directory. Hardening must restrict unnecessary behavior while preserving the files and operations the application needs.

## Learning Goals

- Distinguish Pod and container security settings.
- Explain non-root identity, privilege and capabilities.
- Evaluate filesystem access and writable paths.
- Distinguish admission profile checks from runtime isolation.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. Security Contexts And Profile Requirements
2. Security Contexts And Pod Admission
3. Run Non-Root With A Read-Only Root Filesystem
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
