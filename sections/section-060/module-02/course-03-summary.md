# Summary

A Secret is a namespaced Kubernetes object that stores key and value pairs. The API server keeps each value base64 encoded. Base64 is an encoding that anyone can reverse, so it hides nothing from a person who is allowed to read the Secret. Protection comes from permissions, not from the encoding.

The `kubectl create secret generic` command creates an `Opaque` Secret from literal values, from files and from environment files. A literal value is stored exactly as typed, while a value encoded by hand with `echo` carries a trailing newline that breaks strict comparisons. A file is stored whole under one key, and an environment file becomes one key for each line. The flags `--dry-run=client -o yaml` print the object as YAML without creating it.

Typed Secrets add a check at creation time. A `kubernetes.io/tls` Secret needs the keys `tls.crt` and `tls.key`, and a `kubernetes.io/dockerconfigjson` Secret needs the key `.dockerconfigjson`, which holds the login for a private registry. The type cannot change after creation. In YAML, `stringData` accepts plain text, the API server stores it as `data`, and it never returns `stringData`. If both fields set the same key, `stringData` wins.

An immutable Secret rejects every change and cannot go back to mutable. To change its value, delete it, create it again and restart the pods that use it.

- A Secret exists in one namespace and can only be used by pods in that namespace.
- The total size limit is 1 MiB.
- `--from-literal` adds no newline; `echo` does.
- The default type is `Opaque`; `tls` and `docker-registry` are checked types.
- `immutable: true` is set in YAML or with a patch, and cannot be reversed.

<!-- astrona:playground:destroy -->
