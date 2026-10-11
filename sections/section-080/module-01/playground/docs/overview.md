# Run Non-Root With A Read-Only Root Filesystem Environment

This ungraded playground provides an isolated kind cluster running Kubernetes v1.35.0. It uses its own kubeconfig. The namespace starfleet contains the probe Deployment, the probe Service and the shuttle client Pod. The outpost namespace contains the drifter client. The application reports its version, hostname and greeting on HTTP requests. No task is submitted for grading.

The probe container listens on port 8080 and the Service receives port 80. The application code is supplied through the probe-code ConfigMap. Its /ready and /health paths fail when /tmp/not-ready or /tmp/unhealthy respectively exists in the container. These marker files are controlled practice inputs rather than production health design.

Start the module playground using its launch card. Select its private kubeconfig before application commands:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-080-01)"
kubectl config current-context
kubectl -n starfleet get pods
```

The context must be kind-astro-ats-029-playground-080-01. If it differs, stop and select the module environment. Images and optional addons need network access during first preparation. The container engine must support the pinned kind node image. Local node storage is temporary and does not survive playground destruction.

Inspect actual state and error messages instead of assuming a fixed output. A failed image pull, Pending Pod and failed request concern different boundaries. Astrona prints run-log locations when setup fails; use those logs and kubectl events to identify the first failed dependency.

Destroy and start the module again for a clean reset. The summary supplies the cleanup instruction for the playground. For manual cleanup:

```sh
astrona destroy ats-029-playground-080-01
```

The command takes the environment name rather than a configuration path. The environment is ungraded, so submit is not part of its workflow.
