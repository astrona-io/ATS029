# Question

Solve this question on: `terminal`

The `outpost` namespace enforces the Pod Security Standards level `restricted`. The `bridge` Deployment in `outpost` shows `0/1` ready and has no pod. The container writes `up` to `/tmp/state` and then writes the date to `/work/heartbeat` every few seconds. The security team does not allow any change to the namespace.

1. Find out why the Deployment creates no pod, and fix the pod template of the `bridge` Deployment so that its pod is admitted and the Deployment has one available replica.

2. The pod must not use the host network, and it must not mount a `hostPath` volume. Replace the volume `work` with an `emptyDir` volume of the same name, mounted at `/work`.

3. Run the container as user `1000`, with `runAsNonRoot: true` and the seccomp profile `RuntimeDefault`. The container must block privilege escalation and drop all capabilities.

4. The container must use a read-only root filesystem. The application must still write `/tmp/state` and `/work/heartbeat`, so give it writable volumes at the paths it needs.

Do not change the labels of `outpost`. Keep the container name, the image, the command and one replica. `kubectl` already points at the cluster as the cluster administrator.
