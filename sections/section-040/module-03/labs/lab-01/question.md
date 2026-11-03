# Question

Solve this question on: `terminal`

The `probe` Deployment in the `starfleet` namespace runs two `busybox` pods. It sets the variable `LOG_LEVEL` to the fixed value `warn`, and the application team wants it to use the ConfigMap `probe-settings` instead. That ConfigMap has the keys `LOG_LEVEL`, `REGION` and `probe.properties`. `kubectl` already points at the cluster as the cluster administrator.

1. Change the `LOG_LEVEL` variable of the `probe` container so that its value comes from the key `LOG_LEVEL` of `probe-settings`. It must not have a fixed value.

2. Load every key of `probe-settings` as environment variables with the prefix `SETTING_`. Do not use a prefix for the `LOG_LEVEL` variable of step 1.

3. Mount only the key `probe.properties` of `probe-settings` into the container as the file `/etc/probe/probe.conf`. The file must have mode `0444`, and `/etc/probe` must contain no other file. Do not use `subPath`.

4. Both replicas must run the new configuration and be ready. Do not change the ConfigMap, and do not scale the Deployment.
