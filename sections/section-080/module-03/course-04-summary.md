# Summary

A container shares the kernel of its node, and the pod spec decides how much of that kernel the container reaches. A seccomp profile limits the system calls: `RuntimeDefault` installs the default filter of the container runtime, `Unconfined` turns the filter off, and a pod that sets nothing runs unconfined unless the node makes the runtime default the default. The container field `readOnlyRootFilesystem: true` protects the files of the image, and the application keeps working when `emptyDir` volumes cover the specific directories that it writes to. It applies to the root filesystem only, not to volumes.

A pod can also give up isolation. `hostNetwork`, `hostPID` and `hostIPC` use the namespaces of the node, and a `hostPath` volume mounts files of the node. Each one is useful for a node-level agent and is a risk for an ordinary application. Sysctls set kernel parameters per pod. The kubelet allows only the safe list by default, and a pod with another sysctl is accepted by the API server and then refused by the kubelet with the status `SysctlForbidden`.

Pod Security Admission turns these settings into policy. A namespace label `pod-security.kubernetes.io/<mode>: <level>` picks one of the levels `privileged`, `baseline` and `restricted` for the modes `enforce`, `warn` and `audit`. The `baseline` level rejects host access, privileged containers and unsafe sysctls. The `restricted` level also requires `allowPrivilegeEscalation: false`, dropping all capabilities, `runAsNonRoot: true` and a seccomp profile. Only `enforce` rejects a pod, and it applies to new pods only. A server-side dry run of the label lists the running pods that would break the new level.

A rejected Deployment is accepted by the API server and creates no pod. The ReplicaSet controller sends the pod create request, the API server refuses it, and the message appears as a `FailedCreate` event on the ReplicaSet, listing each failed check with its field. The fix goes in the pod template, never in the namespace label. The key facts to remember are these:

- `readOnlyRootFilesystem` and `allowPrivilegeEscalation` are container-level fields. `sysctls` and `hostNetwork` are pod-level fields.
- Mount an `emptyDir` at the directory the application writes, and keep the rest read-only.
- A rejected Deployment shows `0/1` ready, and the reason is in the ReplicaSet events.
- Fix the pod template. Do not lower the namespace level.

<!-- astrona:playground:destroy -->
