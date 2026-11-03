# Question

Solve this question on: `terminal`

The `scout` Deployment in the `starfleet` namespace reads its API key from a Secret named `scout-credentials`. That Secret does not exist, so the `scout` pod cannot start. The `bridge` team also needs two more Secrets in the same namespace. Create all of them with `kubectl`.

1. Create the generic Secret `scout-credentials` with the key `api-key` and the value `ion-4471`. The value must not contain a trailing newline. The `scout` pod must start and its container must see the value in the environment variable `API_KEY`.

2. Create the generic Secret `bridge-settings` from an environment file. It must have exactly two keys: `REGION` with the value `outpost-4` and `TIER` with the value `gold`.

3. Create the Secret `bridge-registry` for the registry `registry.starfleet.example`, with the user name `fleet-puller` and the password `Warp-9000`. It must have the type `kubernetes.io/dockerconfigjson`.

4. Make `scout-credentials` immutable, after its value is correct.

Do not edit the `scout` Deployment. `kubectl` already points at the cluster as the cluster administrator.
