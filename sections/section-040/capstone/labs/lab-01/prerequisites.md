# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know how to write an immutable ConfigMap as YAML, `configMapKeyRef`, `envFrom` with `prefix`, the `configMap` volume with `items` and `mode`, and how to start a rollout by changing the pod template.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `scout` Deployment in the `starfleet` namespace.
