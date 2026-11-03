# Question

Solve this question on: `terminal`

The `scout` and `probe` Deployments in the `starfleet` namespace run as the `default` ServiceAccount. Both receive an API token, although neither calls the Kubernetes API. The `probe` image must later come from a private registry, and the Secret `regcred` in `starfleet` already holds the registry credential.

1. Create a ServiceAccount named `scout` in `starfleet` that does not mount an API token into its pods. Set the field on the account itself. Make the `scout` Deployment use it. After the rollout, the `scout` pods must have no token volume and must still answer requests.

2. Create a ServiceAccount named `probe` in `starfleet` with `regcred` in its `imagePullSecrets`. Make the `probe` Deployment use it. After the rollout, the `probe` pods must list `regcred` in their `imagePullSecrets`, and they must still mount an API token.

Do not change the `default` ServiceAccount, the `shuttle` Deployment or the `outpost` namespace. Do not delete a Deployment. `kubectl` already points at the cluster as the cluster administrator.
