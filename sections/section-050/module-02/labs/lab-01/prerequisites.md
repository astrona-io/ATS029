# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the difference between a request and a limit, the three QoS classes, and how `kubectl describe pod` shows events.

The lab starts a single-node kind cluster (Kubernetes 1.35) with three Deployments in the `starfleet` namespace.
