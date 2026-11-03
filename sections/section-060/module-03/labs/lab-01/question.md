# Question

Solve this question on: `terminal`

The `probe` Deployment in the `starfleet` namespace holds its database password as a plain value in its pod template, which everyone who can read Deployments can see. The Secrets `probe-credentials` (keys `username` and `password`) and `probe-certificate` (keys `tls.crt` and `tls.key`) already exist, and nothing uses them. The ServiceAccount `auditor` must be able to read the credentials, and nothing else.

1. Change the Deployment `probe` so that the environment variable `DB_PASSWORD` takes its value from the key `password` of the Secret `probe-credentials`. The plain value must be gone from the Deployment.

2. Mount the Secret `probe-certificate` into the `probe` container at `/etc/probe/tls`, read-only. Both files must have the mode `0400`.

3. Allow the ServiceAccount `auditor` to read the Secret `probe-credentials` in `starfleet`, and no other Secret. It must not be able to list Secrets or delete any.

The `probe` pods must be running after the change. Do not change or delete the Secrets. `kubectl` already points at the cluster as the cluster administrator.
