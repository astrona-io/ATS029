---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Allocation, Enforcement And Namespace Policy

A Pod passes its namespace budget but cannot fit on any eligible node. Another Pod runs and then reaches a memory limit. Both concern resources, yet admission, placement and runtime enforcement require different corrections.

## Learning Goals

- Distinguish resource requests from usage and limits.
- Explain CPU and memory enforcement differences.
- Identify defaults and quota admission effects.
- Diagnose allocation policy separately from placement.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. Requests, Limits And Namespace Budgets
2. Observe Quota Rejection And Resource Accounting
3. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
