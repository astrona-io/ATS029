# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`.
- You know the pod-level and container-level fields `runAsUser`, `runAsGroup`, `fsGroup`, `capabilities`, `allowPrivilegeEscalation` and `privileged`, and which of them are valid at which level.

The lab starts a single-node kind cluster (Kubernetes 1.35) with one Deployment.
