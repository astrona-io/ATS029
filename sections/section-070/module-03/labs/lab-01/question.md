# Question

Solve this question on: `terminal`

The `shuttle` pod in the `starfleet` namespace must read the list of pods in its own namespace through the Kubernetes API. Today it runs as the `default` ServiceAccount and the API server answers its request with `403 Forbidden`. The security team wants a dedicated identity with read-only access to pods in `starfleet`, and nothing else.

1. Create a ServiceAccount named `shuttle` in `starfleet`, and make the `shuttle` Deployment use it.

2. Create a Role named `pod-reader` in `starfleet` and a RoleBinding that gives it to the `shuttle` ServiceAccount. The account must be able to `get`, `list` and `watch` pods in `starfleet`, and nothing more.

3. From inside the `shuttle` pod, a request to `https://kubernetes.default.svc.cluster.local/api/v1/namespaces/starfleet/pods` with the mounted token and the mounted `ca.crt` must return HTTP 200. A request for Secrets must still return HTTP 403.

Do not change the `default` ServiceAccount, do not use a ClusterRole or a ClusterRoleBinding, and do not delete a Deployment. `kubectl` already points at the cluster as the cluster administrator.
