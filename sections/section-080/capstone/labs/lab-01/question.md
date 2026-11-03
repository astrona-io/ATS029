# Question

Solve this question on: `terminal`

A new `probe` Deployment must run in the `starfleet` namespace. The namespace enforces the Pod Security Standards level `restricted` and the security team does not allow any change to it. The Deployment shows `0/1` ready and has no pod. Its two containers share a volume: `probe` writes `up` to `/tmp/state` and the date to `/shared/heartbeat`, and `logger` writes the date to `/shared/logger-seen`.

Fix the pod template of the `probe` Deployment so that all of these are true:

1. The pod is admitted and the Deployment has one available replica. Keep the container names, the images, the commands and one replica.

2. The pod does not use the host network and does not mount a `hostPath` volume. The volume `shared` becomes an `emptyDir` mounted at `/shared`, and group `4000` owns it, so files created in it get that group.

3. The pod runs as user `3000` and group `3000` with `runAsNonRoot: true`. The `logger` container runs as user `3500` instead.

4. Both containers drop all capabilities without adding any, block privilege escalation and are not privileged. The pod uses the seccomp profile `RuntimeDefault`.

5. Both containers use a read-only root filesystem. `probe` must still write `/tmp/state`, so give it a writable volume at `/tmp`.

6. The pod sets the safe sysctl `net.ipv4.ip_local_port_range` to `32768 40000`.

`kubectl` already points at the cluster as the cluster administrator.
