---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Secret Consumption And Confidentiality Limits

This module connects intended application behavior to declared resources and observed conditions.

## Learning Goals

- Distinguish Secret representation from encryption.
- Choose mounted or environment-based Secret consumption.
- Explain namespace, workload and registry credential relationships.
- Evaluate who can observe or indirectly obtain confidential data.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. Secret Storage, Delivery And Rotation
2. Credentials And Image Supply Chains
3. Consume A Disposable Secret Without Printing Its Value
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
