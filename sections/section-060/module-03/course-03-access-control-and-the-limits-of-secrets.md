---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Access Control And The Limits Of Secrets

A Secret protects a value only as far as the cluster limits who can read it. The object is base64 encoded, not encrypted, and the API server hands the value to anyone whose request passes the authorization check. This part shows how to give a ServiceAccount permission to read exactly one Secret, how people can read Secrets without asking for them directly, why the encoding gives no protection, and what encryption at rest changes.

## RBAC rules for Secrets

**Role-based access control (RBAC)** is the authorization system of Kubernetes. A **Role** lists rules, and each rule names API groups, resources and verbs. A **RoleBinding** gives a Role to a user, a group or a ServiceAccount in one namespace. A ServiceAccount is an identity that a pod uses when it talks to the API server.

For Secrets, the resource is `secrets` in the core API group, which is written as an empty string. Three verbs return the data: `get` reads one named Secret, `list` returns every Secret in the namespace with its values, and `watch` streams them. People often forget that `list` includes the data, so a Role that allows `list` on `secrets` exposes every value in the namespace.

The playground has a ServiceAccount `auditor` with no permissions. Save this as `role-bridge-credentials-reader.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: bridge-credentials-reader
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["bridge-credentials"]
    verbs: ["get"]
```

Apply it and bind it to the ServiceAccount:

```sh
kubectl apply -f role-bridge-credentials-reader.yaml
kubectl -n starfleet create rolebinding auditor-reads-bridge-credentials \
  --role=bridge-credentials-reader --serviceaccount=starfleet:auditor
```

The `resourceNames` field limits the rule to one Secret by name. The `--serviceaccount` flag takes the form `namespace:name`. Without `resourceNames`, the rule would cover every Secret in the namespace.

## Test the permission with kubectl auth can-i

The command `kubectl auth can-i` asks the API server whether a request would be allowed, without sending it. The `--as` flag runs the question as another identity. The identity of a ServiceAccount is `system:serviceaccount:<namespace>:<name>`.

Then check the result:

```sh
kubectl -n starfleet auth can-i get secret/bridge-credentials --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i get secret/bridge-certificate --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i list secrets --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i delete secret/bridge-credentials --as=system:serviceaccount:starfleet:auditor
```

The first command prints `yes`. The other three print `no`: the other Secret is not named in the rule, `list` is not an allowed verb, and `delete` is not an allowed verb. To see everything the ServiceAccount may do in the namespace, run `kubectl -n starfleet auth can-i --list --as=system:serviceaccount:starfleet:auditor`.

Run a real request as the ServiceAccount to see the denial:

```sh
kubectl -n starfleet get secret bridge-certificate --as=system:serviceaccount:starfleet:auditor
```

The API server answers with a `Forbidden` error that names the identity, the verb and the resource. The `get` of `bridge-credentials` with the same `--as` flag succeeds.

## Indirect access to Secrets

Permission to read Secrets is not the only way to read them. Several other rights give the same result, and a review of RBAC must include them.

A user who can create pods in a namespace can create a pod that mounts any Secret of that namespace or reads it into an environment variable, and then read the value from the pod log or with `exec`. The same is true for the right to create Deployments, Jobs or any object that creates pods. A user who can run `kubectl exec` into a pod can read its environment and the mounted files. A user who can read the pod spec cannot read the value from an `env` reference, but can learn which Secrets exist and which keys the pod uses.

The ServiceAccount token also counts. A pod that runs with a ServiceAccount receives that identity's token in a file. If the ServiceAccount may read Secrets, then every process in the pod, and everyone who can `exec` into it, may read them. Give each workload its own ServiceAccount with only the rules it needs, and turn off the automatic token for pods that never call the API server by setting `automountServiceAccountToken: false`.

The check for the namespace is short. Ask who can create pods, who can `exec`, and who can `get` or `list` Secrets. The answers are the people who can read every Secret there.

## Base64 is not encryption

Look again at what is stored:

```sh
kubectl -n starfleet get secret bridge-credentials -o jsonpath='{.data.username}{"\n"}'
kubectl -n starfleet get secret bridge-credentials -o jsonpath='{.data.username}' | base64 --decode
```

The first command prints a short string of letters and digits. The second turns it back into `bridge-operator` with no key and no password. Base64 exists so that binary values fit in JSON and YAML, not to hide anything. A Secret committed to a Git repository, pasted into a ticket or printed by `kubectl get -o yaml` is readable by everyone who sees the text.

The same applies to the pieces around the Secret. The `kubectl describe` command hides the values and is safe to paste. The `kubectl get secret -o yaml` output is not safe. The `kubectl.kubernetes.io/last-applied-configuration` annotation that `kubectl apply` adds can also hold the values you wrote in `stringData`, so a file with `stringData` leaves a readable copy in the object. Create sensitive Secrets with `kubectl create secret` when you can, because that command does not write the annotation.

## Encryption at rest

The API server keeps all objects in etcd, the key and value database of the control plane. By default etcd stores Secrets in plain form, so anyone who can read the etcd files or a backup can read every Secret. **Encryption at rest** makes the API server encrypt selected resources before it writes them to etcd, and decrypt them when it reads them.

A cluster administrator turns it on with an `EncryptionConfiguration` file and the `--encryption-provider-config` flag of the kube-apiserver. A file like this lives on the control plane node, so you cannot apply it with `kubectl`:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded 32-byte key>
      - identity: {}
```

The API server writes with the first provider in the list, and reads with any provider that matches the stored data. The provider `identity` means no encryption, so keeping it last lets the server still read Secrets that were written before encryption started. Other providers are `secretbox` and `kms`. With `kms`, the data key is protected by an external key management service, so the key does not sit in a file on the control plane node.

Turning it on does not change existing Secrets. Only new writes are encrypted. The administrator must rewrite every Secret, for example with `kubectl get secrets --all-namespaces -o json | kubectl replace -f -`, to encrypt the old ones.

Encryption at rest protects the etcd files and backups. It does not protect against a user with permission to read the Secret, because the API server decrypts the value for every authorized request. It also does not protect the value inside the pod, where any process can read the environment or the file. Each control covers one place, and a safe design uses RBAC, encryption at rest and careful handling by the application together.

## Safe handling in practice

Do not store Secret manifests with real values in a Git repository. Use external tools that keep the value outside the repository and create the Secret in the cluster. Do not print Secrets in logs or in a terminal that is shared. Prefer mounted files with a restrictive mode for long-lived credentials, because a file does not appear in `kubectl describe`, in crash dumps of the environment or in child processes. Rotate a credential by creating the new value, updating the Secret, rolling the pods and then retiring the old value.

You now know how to limit who can read a Secret, how people can read it without a direct permission, and what base64 and encryption at rest do and do not protect.

## Common pitfalls

> [!WARNING]
> - **Allowing `list` on `secrets`.** It returns every Secret in the namespace with its values. Allow `get` on named Secrets.
> - **Forgetting `resourceNames`.** Without it, the rule covers all Secrets in the namespace.
> - **Ignoring pod creation rights.** A user who can create pods can mount any Secret in the namespace.
> - **Pasting `kubectl get secret -o yaml` into a ticket.** Base64 is not encryption.
> - **Assuming encryption at rest hides the value from users.** The API server decrypts it for every authorized request.
