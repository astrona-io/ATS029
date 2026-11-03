---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Summary

A pod uses a ConfigMap through environment variables or through a volume, and the choice decides when a change reaches the application. A rollout is the one method that works for every form of delivery.

## Environment variables

An `env` entry with `valueFrom.configMapKeyRef` sets one variable from one key, and the variable name does not have to match the key. An `envFrom` entry with `configMapRef` loads every key, and an optional `prefix` is added in front of each name. A key that is not a valid variable name, such as one with a dot, is skipped, the pod still starts and the kubelet records an `InvalidEnvironmentVariableNames` event. A missing ConfigMap or key in `configMapKeyRef` or `configMapRef` leaves the pod in `CreateContainerConfigError` unless `optional: true` is set. A variable in `env` wins over the same name in `envFrom`, and a later `envFrom` entry wins over an earlier one. The ConfigMap must be in the namespace of the pod.

## Volumes and updates

A `configMap` volume writes one file for each key, and `items` selects keys, renames them with `path` and sets a `mode`. The `defaultMode` applies to files without their own mode, and modes are octal numbers written with a leading zero. A mount hides the existing content of its target directory, while `subPath` mounts a single file and leaves the directory alone. A missing ConfigMap or listed key keeps the pod in `ContainerCreating` with a `FailedMount` event, unless the volume is `optional`.

The kubelet updates the files of a plain ConfigMap volume after its sync period and cache delay, by switching a `..data` symbolic link to a new directory. The application must read the file again to use the new value. Environment variables, `subPath` mounts and volumes of an immutable ConfigMap never update while the container runs.

## Projected volumes and rollouts

A `projected` volume merges several ConfigMaps, Secrets, `downwardAPI` values and tokens into one directory, and every file path must be unique. A rollout happens only when the pod template of a Deployment changes, so editing a ConfigMap does not start one. `kubectl rollout restart` changes an annotation on the template, a version annotation can do the same, and a new ConfigMap name in the template starts a rollout and keeps the old version for `kubectl rollout undo`.

The key facts to remember are these:

- `configMapKeyRef` is strict by default, `optional: true` makes it tolerant.
- Environment variables are fixed at container start.
- `subPath` mounts never update.
- A plain mount updates after a delay, and only helps an application that rereads its file.
- Only a change of the pod template starts a rollout.

<!-- astrona:playground:destroy -->
