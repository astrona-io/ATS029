---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Creating Generic Secrets

An application needs a password, and that password must not sit in the container image or in the Deployment YAML that many people can read. Kubernetes keeps such values in a Secret, a namespaced object that stores key and value pairs. This part shows the fastest way to create one, `kubectl create secret generic`, and the three places the values can come from: the command line, a file and an environment file.

## What a Secret holds

A **Secret** is a Kubernetes object with a `data` map. Each key is a name such as `password`, and each value is a sequence of bytes that the API server stores after base64 encoding. **Base64** is a way to write any bytes with 64 printable characters. It is an encoding, not encryption: anyone can reverse it with the `base64 --decode` command, and no key is needed.

A Secret lives in one namespace. A pod can only use Secrets from its own namespace, so a Secret created in `outpost` is invisible to a pod in `starfleet`. A Secret has a `type` field. The default type is `Opaque`, which means the contents are arbitrary and Kubernetes checks nothing about the keys. The `kubectl create secret generic` command creates an `Opaque` Secret.

The limits are small. A Secret can hold at most 1 MiB (one mebibyte, 1,048,576 bytes) in total. The name must be a valid DNS subdomain: lowercase letters, digits, dashes and dots. Each key must contain only letters, digits, dashes, underscores and dots.

## Create a Secret from literal values

The `--from-literal` flag takes one `key=value` pair. You can repeat it. The kubectl client encodes each value and sends the Secret to the API server (the Kubernetes control plane component that stores and serves objects).

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet create secret generic probe-credentials \
  --from-literal=username=probe-operator \
  --from-literal=password='Nebula-7421'
```

The command prints `secret/probe-credentials created`. Quote values that contain characters the shell treats as special, such as `$`, `!`, `*` or spaces. Single quotes stop the shell from changing the value.

Read the Secret back. The `describe` command shows the keys and the size of each value, and it never prints the values:

```sh
kubectl -n starfleet describe secret probe-credentials
```

The output lists `Type: Opaque` and a `Data` section with `password` and `username` and their sizes in bytes. To read one value, ask for the base64 text with a JSONPath expression and decode it:

```sh
kubectl -n starfleet get secret probe-credentials -o jsonpath='{.data.password}'
kubectl -n starfleet get secret probe-credentials -o jsonpath='{.data.password}' | base64 --decode
```

The first command prints the encoded text. The second prints `Nebula-7421`. Anyone who can run `kubectl get secret` can do this, which is why access to Secrets is controlled with permissions and not with encoding.

## Create a Secret from files

The `--from-file` flag reads a file and stores its whole content as one value. By default the key is the file name. This is the right way to store a certificate, a private key or a configuration file with several lines, because the shell never touches the content.

Create a small file and store it:

```sh
printf 'region=outpost-4\ntier=gold\n' > scout.properties
kubectl -n starfleet create secret generic scout-properties --from-file=scout.properties
```

The Secret has one key, `scout.properties`, and the value is the full file with both lines. You can choose another key name with `--from-file=settings=scout.properties`, which stores the same content under the key `settings`. If you pass a directory, kubectl creates one key for every regular file in it and skips subdirectories.

The key name matters later. When a pod mounts this Secret as a volume, each key becomes a file name. When a pod reads it as environment variables, a key such as `scout.properties` is not a valid variable name for most shells. Choose keys with the consumer in mind.

## Create a Secret from an environment file

An **environment file** is a text file with one `NAME=value` pair on each line. The `--from-env-file` flag reads it and creates one key for each line. Lines that start with `#` and empty lines are skipped. Unlike `--from-file`, the file itself is not stored; only its pairs are.

```sh
printf 'REGION=outpost-4\nTIER=gold\n' > scout.env
kubectl -n starfleet create secret generic scout-settings --from-env-file=scout.env
```

The Secret `scout-settings` has two keys, `REGION` and `TIER`. Use this form when the application expects each setting as its own environment variable. You can combine all three sources in one command, and you can repeat `--from-file` and `--from-literal`. If two flags produce the same key, the command fails instead of picking one.

## The newline mistake

The most common error comes from creating the value by hand. Suppose you encode a password with `echo`:

```sh
echo 'Nebula-7421' | base64
echo -n 'Nebula-7421' | base64
```

The first command encodes the password plus a trailing newline character, so the stored value is 12 bytes and ends in `\n`. The second command, with `-n`, encodes exactly the 11 characters. An application that compares the password byte by byte rejects the first value. The `--from-literal` flag does not add a newline, so prefer it. When you write the encoded value yourself, always use `echo -n` or `printf`.

A file has the same problem. Most editors add a newline at the end of the last line. When a file holds a single password, create it with `printf '%s' 'value' > file` so that no newline is stored.

## Print the YAML without creating the Secret

Add `--dry-run=client -o yaml` to any create command. The client prints the object and sends nothing to the cluster:

```sh
kubectl -n starfleet create secret generic scout-api \
  --from-literal=api-key=ion-4471 --dry-run=client -o yaml > secret-scout-api.yaml
```

The file contains the Secret with the value base64 encoded under `data`. You can edit it, commit it to a private place, and apply it later with `kubectl apply -f secret-scout-api.yaml`. On the exam this is the quickest way to start from a correct skeleton. Remember that this file now holds the secret value in a form anyone can decode, so treat the file as sensitive.

## Check where the Secret is

Secrets are namespaced. Ask for the same name in the other namespace:

```sh
kubectl -n outpost get secret probe-credentials
```

The API server answers with a `NotFound` error, because the Secret exists only in `starfleet`. To use the same value in `outpost`, you must create a second Secret there. The two objects are independent: changing one does not change the other.

You now know how to create an `Opaque` Secret from literals, files and environment files, how to read a value back, and how to avoid the newline error. The open question is how Kubernetes treats Secrets that are not generic, such as certificates and registry passwords, and how to write any Secret as a YAML file.

## Common pitfalls

> [!WARNING]
> - **Encoding with plain `echo`.** It adds a newline to the value. Use `echo -n`, `printf` or `--from-literal`.
> - **Forgetting the namespace.** `kubectl create secret` uses the current namespace. A Secret in `default` is invisible to a pod in `starfleet`.
> - **Unquoted special characters.** The shell may expand `$` or `!` in a password before kubectl sees it. Use single quotes.
> - **Using `--from-file` and expecting separate variables.** It stores the whole file under one key. Use `--from-env-file` for one key per line.
> - **Treating base64 as protection.** Anyone who can read the Secret can decode it in one command.
