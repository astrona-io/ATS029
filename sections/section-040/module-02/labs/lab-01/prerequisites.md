# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the four `kubectl create configmap` source flags, the `immutable` field and how to change a key of an existing ConfigMap.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `starfleet` namespace and one ConfigMap.
