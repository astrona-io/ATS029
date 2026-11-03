# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`.
- You know the Pod Security levels and modes, the settings the `restricted` level requires, and where a Deployment shows the rejection of its pods.

The lab starts a single-node kind cluster (Kubernetes 1.35) with one namespace and one Deployment.
