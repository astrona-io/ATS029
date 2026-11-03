# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the `kubectl create secret` forms (`generic`, `tls`, `docker-registry`), the flags `--from-literal` and `--from-env-file`, and the `immutable` field.

The lab starts a single-node kind cluster (Kubernetes 1.35) with one Deployment in the `starfleet` namespace. The commands for the lab are in the README of this folder.
