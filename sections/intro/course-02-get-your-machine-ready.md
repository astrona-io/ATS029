# Get Your Machine Ready

Install the Astrona command-line tool, kubectl, kind and Podman. A running Podman machine provides the Linux container environment on macOS. The pinned node image needs a cgroup v2 container environment compatible with kind. Helm is required for package exercises, curl for external requests and OpenSSL for certificate practice. A text editor lets you save the resource files shown in each practical reading.

Check the local toolchain before starting:

```sh
astrona check
kubectl version --client
kind version
podman info
helm version
curl --version
openssl version
```

The playground launch card starts the module environment. For local author checkouts, astrona run accepts the playground configuration directory. Each environment has a separate kubeconfig; select that private file with the command provided in the practical reading rather than relying on an unrelated current cluster.

```sh
astrona list
```

Use the environment name reported by Astrona when manually destroying a playground. If startup fails, inspect the printed log location and the first failing dependency. A registry failure differs from a container-engine connection failure. Do not continue application commands until the module environment is ready.

First starts may download images and selected addons. The practice baseline is Kubernetes v1.35.0, not a claim of the current examination version. Each summary supplies the environment cleanup instruction, and a clean restart provides the declared initial state when experiments change it.
