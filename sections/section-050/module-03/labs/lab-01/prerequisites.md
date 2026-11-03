# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know what a LimitRange and a ResourceQuota do, and where the events of a ReplicaSet show a rejected Pod.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `outpost` namespace.
