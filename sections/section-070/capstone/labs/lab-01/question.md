# Question

Solve this question on: `terminal`

The `bridge` and `scout` Deployments in the `starfleet` namespace both run as the `default` ServiceAccount. A ClusterRoleBinding called `starfleet-default-admin` gives that account `cluster-admin`, so every pod in the namespace holds a token that controls the whole cluster. The `bridge` pod must list pods in its own namespace through the API. The `scout` pod never calls the API. The Secret `regcred` in `starfleet` holds the credential for the registry that will serve the `bridge` image.

1. Remove the cluster-wide administrator access from the `default` ServiceAccount of `starfleet`. Keep the ServiceAccount.

2. Create a ServiceAccount `bridge` with `regcred` in its `imagePullSecrets`. Give it a Role in `starfleet` that allows only `get`, `list` and `watch` on pods, and a RoleBinding. Make the `bridge` Deployment use the account. From inside the `bridge` pod, listing pods with the mounted token must return HTTP 200, and listing Secrets must return HTTP 403. The new `bridge` pods must list `regcred` in their `imagePullSecrets`.

3. Create a ServiceAccount `scout` that does not mount an API token, with the setting on the account. Make the `scout` Deployment use it. The `scout` pods must have no token volume and must still answer requests from `bridge`.

Do not delete a Deployment and do not change the `regcred` Secret. `kubectl` already points at the cluster as the cluster administrator.
