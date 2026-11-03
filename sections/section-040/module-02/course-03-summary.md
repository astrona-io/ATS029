---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Summary

A ConfigMap is a namespaced object that stores non-secret configuration as string keys and values. The key names are the contract with every pod that uses the object, so the most important skill is to predict the keys a command produces before you run it.

## Choosing a source

`kubectl create configmap` has four source forms, and each one names its keys in a different way. `--from-literal=key=value` creates the key you type. `--from-file=PATH` stores the whole file as one value under the file name, and `--from-file=KEY=PATH` stores it under a key you choose. `--from-env-file=PATH` reads a file with one `NAME=value` line per key and creates one key for each line, skipping comment lines and empty lines. `--from-file=DIRECTORY` creates one key for each regular file directly inside the directory. You cannot combine `--from-env-file` with the other file and literal flags.

A key may contain only letters, digits, a dash, an underscore and a dot, and the API server rejects any other key. Keys meant for environment variables should be uppercase with underscores. Keys meant for files should be the real file name the application expects.

## Content, size and previews

The `data` field holds UTF-8 text and the `binaryData` field holds base64-encoded bytes. kubectl places a file in `binaryData` when it is not valid UTF-8, and a key must be unique across both fields. The whole object must stay below 1 MiB, so large files belong in a volume, an image or an object store. A client-side dry run with `--dry-run=client -o yaml` prints the object without creating it, and piping that output into `kubectl apply -f -` is the usual way to update an existing ConfigMap, because `create` fails with `AlreadyExists`.

## Immutability and changing objects

Setting `immutable: true` locks `data` and `binaryData`. The API server then refuses every change to them, and you cannot set the field back to `false`. The only way to change the content is to delete the object and create it again, or to create a new object with a new name and point the workload at it. The kubelet stops watching an immutable ConfigMap, which reduces load on the API server. For a mutable ConfigMap, `kubectl edit`, `kubectl patch` and `kubectl apply` change single keys, while `kubectl replace` swaps the whole object and removes every key that is missing from the file.

The key facts to remember are these:

- The source flag decides the key names.
- `--from-env-file` makes one key per line; `--from-file` makes one key per file.
- `data` is text, `binaryData` is base64 bytes, and the object must stay below 1 MiB.
- `immutable: true` cannot be undone.
- `kubectl replace` removes keys that are not in the file.

<!-- astrona:playground:destroy -->
