# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `openssl` on your own machine.
- You know how a client certificate becomes a user and groups, how a CertificateSigningRequest is approved, how a Role is bound to a group, and how a `ValidatingAdmissionPolicy` and its binding reject a request.

The lab starts a single-node kind cluster (Kubernetes 1.35) with two namespaces.
