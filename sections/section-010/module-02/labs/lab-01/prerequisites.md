# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can write a CustomResourceDefinition (CRD) with a schema, defaults, printer columns and a status subresource, and you know the `Established` condition.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the namespaces `starfleet` and `outpost`.
