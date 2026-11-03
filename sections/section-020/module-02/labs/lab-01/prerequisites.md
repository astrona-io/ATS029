# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `openssl` on your own machine.
- You know how a client certificate identifies a user, how a CertificateSigningRequest is approved, and how `kubectl config set-credentials` and `kubectl config set-context` build a context.

The lab starts a single-node kind cluster (Kubernetes 1.35) with two namespaces.
