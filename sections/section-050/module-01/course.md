---
draft: true
exam_objectives:
- Define resource requirements
---
# Complete Container Resource Requirements

This module connects intended application behavior to declared resources and observed conditions.

## Learning Goals

- Interpret CPU and memory quantities correctly.
- Account for helpers and initialization lifecycle.
- Explain admitted defaults and complete Pod needs.
- Distinguish scheduling, throttling and memory termination.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. Expressing Resource Needs For Every Container
2. Declare Resources For Every Ordinary Container
3. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
