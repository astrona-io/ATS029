# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can read an operator log, check the permissions of a service account with `kubectl auth can-i --as`, read owner references, and clear a finalizer with `kubectl patch`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an operator for the kind `Hangar`.
