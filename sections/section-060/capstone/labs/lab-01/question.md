# Question

Solve this question on: `terminal`

The `bridge` Deployment in the `starfleet` namespace runs with an old password written as a plain value in its pod template. The Secret `bridge-credentials` (keys `username` and `password`) holds the same old password. The password was rotated to `Pulsar-2026`, and the team wants the Deployment to consume the Secret, pull images with a registry login, and let the `auditor` ServiceAccount read the credentials and nothing else.

1. Change the password in the Secret `bridge-credentials` to `Pulsar-2026`. Keep the `username` key as it is.

2. Create the Secret `bridge-registry` for the registry `registry.starfleet.example`, with the user name `fleet-puller` and the password `Warp-9000`. The `bridge` pods must reference it as an image pull Secret.

3. Change the Deployment `bridge` so that `BRIDGE_PASSWORD` takes its value from the key `password` of `bridge-credentials`, with no plain value left. The running pod must have the new password.

4. Mount only the `password` key of `bridge-credentials` at `/etc/bridge/credentials`, read-only, with the file mode `0400`. The `username` file must not be in the container.

5. Allow the ServiceAccount `auditor` to `get` the Secret `bridge-credentials` in `starfleet`, and no other Secret. It must not be able to list or change Secrets.

`kubectl` already points at the cluster as the cluster administrator.
