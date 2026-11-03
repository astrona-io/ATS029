# Summary

A container is a Linux process, and the `securityContext` of a pod or a container sets the identity and the privilege of that process. The fields `runAsUser`, `runAsGroup` and `runAsNonRoot` work at both levels. A container-level value replaces the pod-level value, field by field, and a container without its own value uses the pod value. The fields `fsGroup` and `supplementalGroups` work at pod level only.

Linux checks numbers, not names. A user name in an image is only a label for a user ID, so `runAsNonRoot: true` with an image that runs as root or has a named user makes the kubelet refuse to start the container with `CreateContainerConfigError`. A numeric `runAsUser` fixes that. Volume ownership follows the same logic. The `fsGroup` value becomes the group of supported volumes, the setgid bit on the directory gives new files that group, and the kubelet adds the `fsGroup` to the supplementary groups of every container in the pod.

Root is a set of capabilities, and a container starts with a default subset. The field `capabilities` at container level removes entries with `drop`, adds entries with `add`, and the value `ALL` stands for every capability. The names are written without the `CAP_` prefix. The command `chown` is a quick test, because it needs `CHOWN` and fails with `Operation not permitted` when that capability is gone.

Two more settings decide how much power a process can reach. `allowPrivilegeEscalation: false` sets the `no_new_privs` flag, so setuid files and file capabilities give no extra privilege, and it is always on for privileged containers. `privileged: true` gives all capabilities and all host devices, and the API server rejects it together with `allowPrivilegeEscalation: false`. The key facts to remember are these:

- Container-level identity fields win over pod-level fields, one field at a time.
- `fsGroup` and `supplementalGroups` are pod-level only. `capabilities` and `allowPrivilegeEscalation` are container-level only.
- Use a numeric `runAsUser` together with `runAsNonRoot: true`.
- Start from `drop: ["ALL"]` and add back only what the process needs.

<!-- astrona:playground:destroy -->
