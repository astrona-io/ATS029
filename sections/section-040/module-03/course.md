---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Consuming ConfigMaps In Pods

A ConfigMap does nothing until a pod uses it. A pod can read the keys as environment variables or as files in a volume, and the two methods behave very differently when the ConfigMap changes later. On the Certified Kubernetes Application Developer exam you must wire a ConfigMap into a pod quickly and correctly, and you must know which method picks up a change and which one never does.

Keep one sentence in mind for this module: **the way a pod consumes a ConfigMap decides when a change reaches the application, and a rollout is the only method that works for every delivery form.** You will inject single keys and whole ConfigMaps as environment variables, mount ConfigMaps as volumes with selected keys and file modes, measure how a change travels into a running container, merge several sources into one directory, and roll out a Deployment when its configuration changes.

The module has three parts. **ConfigMap Values As Environment Variables** covers `env` with `configMapKeyRef`, `envFrom` with a prefix, the `optional` field, invalid variable names and what a missing key does to a pod. **ConfigMap Volumes, File Modes And Update Propagation** covers the `configMap` volume, the `items` list, file modes, the `subPath` limit and how long an update takes to reach the files. **Projected Volumes And Rollouts On Change** covers the `projected` volume that merges several sources and the three ways to make a Deployment pick up a changed ConfigMap.

## Learning objectives

After this module you can:

- Set one environment variable from one ConfigMap key with `configMapKeyRef`, and load all keys with `envFrom`, with and without a prefix.
- Predict what happens when a ConfigMap, a key or a variable name is missing, and use `optional: true` on purpose.
- Mount a ConfigMap as a volume, mount only selected keys with `items`, set `defaultMode` and a per-key `mode`, and mount a single file with `subPath`.
- Explain which delivery methods receive an update of the ConfigMap and which never do.
- Merge a ConfigMap and other sources into one directory with a `projected` volume.
- Roll out a Deployment after a configuration change with `kubectl rollout restart`, a changed pod template annotation or a new immutable ConfigMap name.

## Before you start

You need to know how to create a ConfigMap with `kubectl create configmap`, and how to write a pod and a Deployment as YAML. You do not need to know projected volumes or rollout strategies; this module explains them.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | A ConfigMap `scout-settings` with the keys `LOG_LEVEL`, `REGION`, `app.properties` and `banner.txt`, and a `viewer` Deployment that runs one `busybox` pod you can use for `kubectl exec` |

`kubectl` already points at the playground cluster, as the cluster administrator. You save the example files in your own working directory, with the "Save this as" steps in the parts.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
