# Question

Solve this question on: `terminal`

The `scout` Deployment in the `starfleet` namespace runs two `busybox` pods and has no configuration. The team needs a versioned configuration that cannot be edited in place, and then needs one setting changed. `kubectl` already points at the cluster as the cluster administrator.

1. Create the ConfigMap `scout-config-v1` in `starfleet`. It must be immutable and have three keys: `LOG_LEVEL` with the value `info`, `REGION` with the value `outpost-7`, and `scout.conf` with the two lines `interval=10` and `timeout=2`.

2. The settings change: `LOG_LEVEL` must now be `debug`. Because `scout-config-v1` is immutable, create a second ConfigMap `scout-config-v2` with the same three keys and values, except that `LOG_LEVEL` is `debug`. It must be immutable too. Keep `scout-config-v1`.

3. Configure the `scout` container so that it uses `scout-config-v2` only:
   - The variable `LOG_LEVEL` comes from the key `LOG_LEVEL` through `configMapKeyRef`.
   - All keys of the ConfigMap are also loaded as environment variables with the prefix `SCOUT_`.
   - Only the key `scout.conf` is mounted as the file `/etc/scout/scout.conf`, with mode `0440`, and `/etc/scout` contains no other file. Do not use `subPath`.

4. Both replicas must run the new configuration and be ready. Do not scale the Deployment.
