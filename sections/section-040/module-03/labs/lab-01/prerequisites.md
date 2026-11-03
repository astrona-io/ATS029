# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know `configMapKeyRef`, `envFrom` with `prefix`, the `configMap` volume with `items` and `mode`, and how a pod template change starts a rollout.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `probe` Deployment and the `probe-settings` ConfigMap in the `starfleet` namespace.
