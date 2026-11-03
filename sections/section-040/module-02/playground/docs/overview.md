# Overview: Creating ConfigMaps (Playground)

This is a playground, not a lab. It starts a fresh cluster with one namespace and one idle pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Create ConfigMaps, break them, delete them and start over.

## What is in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | A `viewer` Deployment that runs one `busybox` pod you can use for `kubectl exec`. No ConfigMaps of your own exist yet, only the `kube-root-ca.crt` ConfigMap that Kubernetes adds to every namespace |

You create the example files in your own working directory.

## Helpers

Paste this once in each new terminal. `show_keys` prints the key names of a ConfigMap in `starfleet`, one per line, for both `data` and `binaryData`.

```sh
show_keys() {
  kubectl -n starfleet get configmap "$1" -o go-template='{{range $key, $value := .data}}{{$key}}{{"\n"}}{{end}}{{range $key, $value := .binaryData}}{{$key}}{{"\n"}}{{end}}'
}
```

Use it like this: `show_keys scout-env`. It prints one key name per line.

## Practice tasks

- Create a ConfigMap from two literals. Predict the keys before you read them back.
- Save a file called `app.properties` and create a ConfigMap with `--from-file`. Then create a second one with `--from-file=settings.properties=app.properties` and compare the keys.
- Create an environment file with a comment line, an empty line and three settings. Predict how many keys the ConfigMap has, then check.
- Create a directory with three files and one subdirectory that holds a fourth file. Predict which keys appear.
- Try to create a ConfigMap with a key that contains a space. Read the error message.
- Make a 16-byte random file with `head -c 16 /dev/urandom > blob.bin` and find out whether it lands in `data` or `binaryData`.
- Apply a ConfigMap with `immutable: true`. Try to change its data with `kubectl patch`, then delete and re-create it.
- Update one key of a mutable ConfigMap with `kubectl patch`, then use `kubectl replace` with a file that has fewer keys and see which keys disappear.
