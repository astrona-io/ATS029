---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# ConfigMaps And Application Configuration Delivery

A ConfigMap changes, but the running process keeps its startup environment value. The object was updated successfully; adoption did not occur through that delivery method. Configuration maintenance needs both delivery and consumption to be explained.

## Learning Goals

- Choose ConfigMap delivery through files or environment.
- Explain namespace and key references.
- Distinguish object updates from process configuration reload.
- Diagnose missing or incompatible application configuration.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. ConfigMaps, Secrets And Configuration Delivery
2. Configuration, Dependencies And Request Failures
3. Compare Environment And Mounted ConfigMap Updates
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
