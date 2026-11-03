---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Secret Types, stringData And Immutability

A generic Secret accepts any keys, so a typing mistake is only found when the application fails. Kubernetes also has typed Secrets that the API server checks when you create them: a `tls` Secret must carry a certificate and a key, and a `docker-registry` Secret must carry a valid registry login file. This part covers those types, the YAML form of a Secret with `stringData`, and the `immutable` field that locks a Secret against changes.

## The Secret type

The `type` field of a Secret tells Kubernetes and the tools that read it what the Secret is for. For some types the API server also checks that required keys exist. These are the types you need to know:

| Type | Required keys | Used for |
| --- | --- | --- |
| `Opaque` | none | Any data. This is the default |
| `kubernetes.io/tls` | `tls.crt`, `tls.key` | A certificate and its private key, for example for an Ingress |
| `kubernetes.io/dockerconfigjson` | `.dockerconfigjson` | Registry login for pulling images |
| `kubernetes.io/basic-auth` | `username` or `password` | A user name and password |
| `kubernetes.io/ssh-auth` | `ssh-privatekey` | An SSH private key |
| `kubernetes.io/service-account-token` | set by Kubernetes | A long-lived ServiceAccount token |

The type is fixed when the Secret is created. You cannot change the type of an existing Secret; you delete it and create it again. The type does not encrypt anything. It only adds a check at creation time and tells other components which keys to look for.

## Create a tls Secret

A **TLS Secret** stores a certificate and a private key. TLS (Transport Layer Security) is the protocol that encrypts network connections. The command `kubectl create secret tls` reads two files and stores them under the keys `tls.crt` and `tls.key`, with the type `kubernetes.io/tls`.

Create a self-signed certificate for the exercise on your own machine. The `openssl` command writes the key and the certificate to two files:

<!-- astrona:playground:renew -->

```sh
openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -keyout bridge.key -out bridge.crt -subj "/CN=bridge.starfleet.example"
kubectl -n starfleet create secret tls bridge-tls --cert=bridge.crt --key=bridge.key
```

Then check the type and the keys:

```sh
kubectl -n starfleet get secret bridge-tls -o jsonpath='{.type}{"\n"}'
kubectl -n starfleet describe secret bridge-tls
```

The type is `kubernetes.io/tls` and the data section lists `tls.crt` and `tls.key`. If you try to create a secret of this type from a generic command without those two keys, the API server rejects the request with a validation error that names the missing key. That check is the benefit of the type.

## Create a docker-registry Secret

A **registry** is a server that stores container images. A private registry asks for a login before it lets a node download an image. The Secret that carries this login has the type `kubernetes.io/dockerconfigjson`, and its single key `.dockerconfigjson` holds a JSON (JavaScript Object Notation) document in the format of a container tool login file.

The `kubectl create secret docker-registry` command builds that document for you:

```sh
kubectl -n starfleet create secret docker-registry bridge-registry \
  --docker-server=registry.starfleet.example \
  --docker-username=fleet-puller \
  --docker-password='Warp-9000' \
  --docker-email=puller@starfleet.example
```

Decode the stored document to see its structure:

```sh
kubectl -n starfleet get secret bridge-registry -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode
```

The key starts with a dot, so the JSONPath expression escapes it with a backslash. The decoded document has an `auths` object. Under it, the registry server name is the key, and the value holds the `username`, the `password`, the `email` and an `auth` field. The `auth` field is the user name, a colon and the password, base64 encoded. The kubelet (the agent on each node that starts containers) reads this document when it pulls an image for a pod that references the Secret.

## Write a Secret as YAML with stringData

The YAML form has two fields for values. The `data` field takes base64 text. The `stringData` field takes plain text, and the API server encodes it for you when it stores the object. `stringData` is write-only: when you read the Secret back, you see only `data`.

Save this as `secret-scout-credentials.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scout-credentials
  namespace: starfleet
type: Opaque
stringData:
  username: scout-operator
  api-key: ion-4471
```

Apply it:

```sh
kubectl apply -f secret-scout-credentials.yaml
```

Then check the result:

```sh
kubectl -n starfleet get secret scout-credentials -o yaml
```

The output has a `data` map with both keys encoded, and no `stringData` field. If a key appears in both `data` and `stringData`, the `stringData` value wins. Use `stringData` when you write YAML by hand, because you avoid encoding by hand and the newline mistake. Use `data` only when you paste a value that is already encoded.

Applying a changed `stringData` value updates only the keys you list. Keys that are in the stored Secret but not in the file stay as they are. This is why a rerun of `kubectl apply` after you remove a key from the file does not remove the key from the Secret.

## Make a Secret immutable

An **immutable** Secret cannot be changed after creation. The field `immutable: true` is a boolean at the top level of the Secret, next to `type`. When it is set, the API server rejects any change to `data`, `stringData` and `type`, and you cannot set it back to `false`. You can only delete the Secret and create it again.

Immutability has two benefits. It protects against an accidental edit that would break every pod using the Secret. It also lets the kubelet stop watching the Secret for changes, which lowers the load on the API server in clusters with many Secrets.

Set the field on the existing Secret with a patch:

```sh
kubectl -n starfleet patch secret scout-credentials -p '{"immutable":true}'
```

Now try to change a value. The patch fails with a validation error that says the field is immutable:

```sh
kubectl -n starfleet patch secret scout-credentials -p '{"stringData":{"api-key":"ion-9999"}}'
```

To change an immutable Secret, delete it, create it again with the new value, and restart the pods that use it so they pick up the new object. Because the name stays the same, pods that already run keep the old value until they restart. Some teams put a version in the name, for example `scout-credentials-v2`, and change the name in the Deployment so the rollout happens by itself.

You can only turn immutability on when you create the Secret in YAML or with a patch. The `kubectl create secret` command has no flag for it.

## Clean up the files

The files you created hold secret values in plain text. Remove them from your machine when you finish:

```sh
rm -f bridge.key bridge.crt scout.properties scout.env secret-scout-api.yaml
```

You now know the built-in Secret types, the three create commands, the YAML form with `stringData`, and how to lock a Secret. The open question is how a pod reads these values, which is the subject of consuming Secrets.

## Common pitfalls

> [!WARNING]
> - **Expecting `stringData` in the output.** The API server converts it to `data` and never returns it.
> - **Trying to change the type of an existing Secret.** The type is fixed; delete and create the Secret again.
> - **Editing an immutable Secret.** The request is rejected. Create a new Secret and roll the pods.
> - **Believing a rerun of `kubectl apply` removes keys.** Keys missing from the file stay in the stored Secret.
> - **Leaving key and certificate files on disk.** They hold the same secrets in plain text. Delete them.
