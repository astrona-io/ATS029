# Question

Solve this question on: `terminal`

The `scout` team in the `starfleet` namespace needs three new ConfigMaps, and the old `probe-settings` ConfigMap needs one change. Work in your own working directory and create any source files there. `kubectl` already points at the cluster as the cluster administrator.

1. Create the ConfigMap `scout-env` from an environment file that has the two lines `MODE=fast` and `RETRIES=3`. The ConfigMap must have exactly the two keys `MODE` and `RETRIES`.

2. Create the ConfigMap `scout-files` with two keys. The key `app.properties` must hold a file with the two lines `retries=3` and `region=outpost-7`. The key `banner.txt` must hold the single line `scout online`. The file on your machine that holds the properties may have any name.

3. Create the ConfigMap `scout-locked` with the single key `LOG_LEVEL` set to `warn`. Nobody may be able to change its data later.

4. The existing ConfigMap `probe-settings` has `LOG_LEVEL` set to `trace`. Change `LOG_LEVEL` to `info`. Keep the key `probe.conf` unchanged and do not lock the object.

Do not delete the namespace and do not create the objects in another namespace.
