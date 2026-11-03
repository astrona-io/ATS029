# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can create Secrets with `kubectl create secret`, consume them as environment variables and volumes, reference an image pull Secret, and write a Role with `resourceNames`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `starfleet` namespace. The commands for the lab are in the README of this folder.
