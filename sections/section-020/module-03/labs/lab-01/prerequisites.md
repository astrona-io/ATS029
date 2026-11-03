# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` on your own machine.
- You know what a `LimitRange` does, how to write a `ValidatingAdmissionPolicy` with a CEL expression and a `ValidatingAdmissionPolicyBinding`, and how `kubectl apply --dry-run=server` previews a decision.

The lab starts a single-node kind cluster (Kubernetes 1.35) with two namespaces.
