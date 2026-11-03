---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Creating ConfigMaps

A ConfigMap is a Kubernetes object that stores non-secret configuration as key-value pairs, so the same container image can run with different settings. Before a pod can use configuration, someone has to create the object, and the way you create it decides the exact keys the pod will see. A wrong key name is the most common reason a pod fails to start with configuration that "exists".

Keep one sentence in mind for this module: **the source you give to `kubectl create configmap` decides the key names, and the key names are the contract with every pod that uses the ConfigMap.** You will create ConfigMaps from literal values, from single files, from environment files and from whole directories, and you will see exactly which keys each form produces.

The module has two parts. **Creating ConfigMaps From Literals, Files And Directories** covers the four `kubectl create configmap` source flags, how each one names its keys, the rules for key names and how to preview an object with a client-side dry run. **Data, Binary Data, Limits And Immutability** covers the two data fields of a ConfigMap, the 1 MiB size limit, the `immutable` field and the commands that show, edit and replace an existing ConfigMap.

## Learning objectives

After this module you can:

- Create a ConfigMap with `kubectl create configmap` from literals, a file, a file with a chosen key, an environment file and a directory.
- Predict the keys a command produces and choose a key name that a pod can use.
- Preview a ConfigMap as YAML with `--dry-run=client -o yaml` before you create it.
- Explain the difference between the `data` and `binaryData` fields and the 1 MiB size limit.
- Set `immutable: true` and explain what it blocks and how to change an immutable ConfigMap.
- Inspect, edit and replace a ConfigMap with `kubectl get`, `describe`, `edit` and `replace`.

## Before you start

You need Kubernetes basics: namespaces, pods, and the commands `kubectl get`, `kubectl apply` and `kubectl describe`. You do not need to know how pods consume a ConfigMap; this module only creates and inspects the objects.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | A `viewer` Deployment that runs one `busybox` pod you can use for `kubectl exec`. No ConfigMaps of your own exist yet, only the `kube-root-ca.crt` ConfigMap that Kubernetes adds to every namespace |

`kubectl` already points at the playground cluster, as the cluster administrator. You create the example files in your own working directory, with the "Save this as" steps in the parts.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
