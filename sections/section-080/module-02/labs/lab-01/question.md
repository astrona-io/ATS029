# Question

Solve this question on: `terminal`

The `shuttle` Deployment in the `starfleet` namespace has two containers, `shuttle` and `relay`. Both share an `emptyDir` volume mounted at `/data`, and `shuttle` writes the file `/data/heartbeat` every few seconds. The `shuttle` container runs privileged, and both containers run as root. The security team wants the privileges removed and the identity fixed, and the file must keep being written.

1. Remove the privileged mode from the `shuttle` container.

2. In the pod-level `securityContext`, run the pod as user `1500` and group `3000`. The `relay` container must run as user `2500` instead, with group `3000`.

3. Make the group `4000` own the shared volume, so that `/data` has group `4000` and files created in it get that group.

4. Both containers must block privilege escalation and drop all capabilities. They must not add any capability.

Keep the container names, the images, the commands and one replica. Every replica must be available after the change. `kubectl` already points at the cluster as the cluster administrator.
