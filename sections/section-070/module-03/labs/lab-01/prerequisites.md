# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can create a Role and a RoleBinding, and you know the difference between a `401` and a `403` response from the API server.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads. The commands for the lab are in the README of this folder.
