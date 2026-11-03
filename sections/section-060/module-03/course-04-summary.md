# Summary

A pod receives a Secret only through its own spec. There are three delivery methods, and each one has its own failure messages and its own update behavior.

An environment variable is filled by the kubelet when the container starts. A `secretKeyRef` injects one key under any variable name, and `envFrom` injects every key, with an optional prefix. A wrong Secret name or key leaves the pod in `CreateContainerConfigError`, and the pod events name what is missing. The `optional` field lets the container start without the value. A running container never sees a changed Secret, so a rotation needs a rollout of the Deployment.

A Secret volume writes one file for each key to an in-memory directory. The `items` list mounts only chosen keys under chosen names, and `defaultMode` and the item `mode` set the file permissions in octal. Mounted files update after a delay, because the kubelet syncs periodically, but a `subPath` mount, an immutable Secret and an environment variable do not update. A projected volume combines several Secrets and other sources in one directory. A private registry login is a `kubernetes.io/dockerconfigjson` Secret that a pod lists in `imagePullSecrets`, either directly or through its ServiceAccount, in the same namespace as the pod.

Access control decides who can read a Secret. A Role with `get` on named Secrets through `resourceNames` is the narrow form, and `kubectl auth can-i` with `--as` tests it. The verb `list` returns every value in the namespace. The rights to create pods and to run `exec` give indirect access to every Secret the pods can use. Base64 is an encoding that anyone can reverse. Encryption at rest protects the data stored in etcd and in backups, but the API server still returns the plain value to every authorized request, and any process in the pod can read it.

- Environment variables are fixed at container start; mounted files can update; `subPath` mounts cannot.
- `CreateContainerConfigError` means the Secret or key in a reference is missing.
- `defaultMode: 0400` is the same number as `256` in decimal.
- `imagePullSecrets` belongs in the pod spec or on the ServiceAccount, in the pod namespace.
- Allow `get` with `resourceNames`; avoid `list` on `secrets`.

<!-- astrona:playground:destroy -->
