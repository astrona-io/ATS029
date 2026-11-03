---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# kubeconfig Contexts And Access Checks

A signed certificate and a private key are two files. `kubectl` needs them inside a `kubeconfig` file, together with the address of the API server and the CA certificate that proves the server is genuine. A mistake in this file sends commands to the wrong cluster or the wrong namespace, and the exam has many clusters and namespaces. This part explains the structure of a `kubeconfig` file, builds a context for a new user, and shows three ways to check what an identity may do.

## What a kubeconfig file contains

A **kubeconfig** file is a YAML file that tells `kubectl` which API server to call and which credential to use. By default `kubectl` reads `~/.kube/config`. The `KUBECONFIG` environment variable and the `--kubeconfig` flag change the file. The file has three lists and one pointer:

- `clusters` holds the server address and the CA certificate that `kubectl` uses to verify the API server.
- `users` holds credentials: a client certificate and key, a token, or a command that fetches a token.
- `contexts` holds named combinations of one cluster, one user and an optional default namespace.
- `current-context` names the context that `kubectl` uses when you give no `--context` flag.

A cluster entry and a user entry are independent. A context joins them. This is why you can give a new user access to the same cluster by adding one user entry and one context entry. Look at your current context without the secret data:

<!-- astrona:playground:renew -->

```sh
kubectl config get-contexts
kubectl config view --minify
```

The first command lists every context and marks the current one with `*`. The second prints only the entries that the current context uses. The `--minify` flag removes the rest, and `kubectl config view` replaces certificate data with `DATA+OMITTED`. Add `--raw` only when you need the real data, because it prints secrets.

## Add a user and a context

Find the cluster name first, because a new context must use the same cluster entry as the current one. The next command stores that name in a shell variable.

```sh
CLUSTER_NAME="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
echo "$CLUSTER_NAME"
```

The commands below need the files `ensign-chen.key` and `ensign-chen.crt` in the current directory. They hold the private key and the signed certificate of the user `ensign-chen` with the group `bridge-crew`. Create the user entry and the context:

```sh
kubectl config set-credentials ensign-chen --client-key=ensign-chen.key --client-certificate=ensign-chen.crt --embed-certs=true
kubectl config set-context ensign-chen --cluster="$CLUSTER_NAME" --user=ensign-chen --namespace=outpost
```

The flag `--embed-certs=true` copies the key and the certificate into the `kubeconfig` file as base64 data. Without it, the file stores only the paths of the two files, and the context stops working when you move or delete them. The flag `--namespace=outpost` sets the default namespace of the context, so `kubectl get pods` without `-n` reads `outpost`.

Now call the API server through the new context:

```sh
kubectl --context ensign-chen auth whoami
```

The table shows the username `ensign-chen` and the groups `bridge-crew` and `system:authenticated`. This proves that the API server accepted the certificate and read the subject from it.

## A user that has a token instead of a certificate

A user entry can hold a token. Create a token for the `shuttle` ServiceAccount and store it as a second user, with a second context:

```sh
kubectl config set-credentials shuttle-token --token="$(kubectl -n starfleet create token shuttle)"
kubectl config set-context shuttle --cluster="$CLUSTER_NAME" --user=shuttle-token --namespace=starfleet
kubectl --context shuttle auth whoami
```

The username is `system:serviceaccount:starfleet:shuttle`. Use a separate user entry for the token. If you put a token and a certificate in the same entry, the API server may authenticate the certificate first and ignore the token, which hides the problem you are testing.

To work in another context for a while, run `kubectl config use-context ensign-chen`. This changes `current-context` in the file. For one command, the `--context` flag is safer, because it changes nothing that you can forget. To change only the namespace of the current context, run `kubectl config set-context --current --namespace=starfleet`.

> [!TIP]
> On the exam, run `kubectl config current-context` first and after each switch. A correct command in the wrong cluster scores nothing.

## Three ways to check access

The new user has no Role yet, so every request is denied after authentication. Try it:

```sh
kubectl --context ensign-chen get pods
```

The command fails with `Forbidden` and names the user `ensign-chen`, the verb `list`, the resource `pods` and the namespace `outpost`. The credential works. Authorization has no grant for it.

The first check is the real one: use the context and see if the request works. The second check asks the API server a question without doing the action. The command `kubectl auth can-i` sends a `SelfSubjectAccessReview` and prints `yes` or `no`. It exits with code 1 when the answer is `no`, so scripts can use it:

```sh
kubectl --context ensign-chen auth can-i list pods
kubectl --context ensign-chen auth can-i list pods --namespace starfleet
```

The third check needs no new context. A user with the `impersonate` verb can ask the question for another identity. The cluster administrator has it. The flag `--as` sets the user and `--as-group` sets a group:

```sh
kubectl auth can-i list pods --namespace outpost --as ensign-chen --as-group bridge-crew
```

Impersonation sends a request as the administrator, with extra headers that name another identity. The API server then authorizes the request as that identity. It is the fastest check, because you need no key and no context. It does not test authentication, so a typo in the name still gives an answer.

## Bind a group and read the result

Authorization grants rights to the group that came from the certificate, not only to the user. Create a read-only Role and bind it to the group `bridge-crew`:

```sh
kubectl -n outpost create role pod-reader --verb=get,list,watch --resource=pods
kubectl -n outpost create rolebinding bridge-crew-pod-reader --role=pod-reader --group=bridge-crew
```

Check through the context, then print every right the user has in the namespace:

```sh
kubectl --context ensign-chen get pods
kubectl --context ensign-chen auth can-i --list --namespace outpost
```

The first command lists the `drifter` pod. The second prints a table of resources and verbs. It shows the three verbs on `pods`, and it also shows a few rights that every authenticated user gets, such as creating a `SelfSubjectAccessReview`. The same user in `starfleet` still receives `Forbidden`, because a RoleBinding grants rights only in its own namespace.

You can now build a working context for a new identity and prove its limits with three tools. The command `kubectl auth can-i` is the one you will use most on the exam.

## Common pitfalls

> [!WARNING]
> - **Forgetting `--embed-certs=true`.** The `kubeconfig` then stores file paths, and the context fails after the files move.
> - **Reading `--minify` output as the whole file.** It shows only the current context. Other contexts exist in the same file.
> - **Trusting `--as` for authentication.** Impersonation tests authorization only. It never proves that a certificate or token works.
> - **Omitting the namespace in `can-i`.** Without `--namespace`, the check uses the namespace of the context, which is not always the one you mean.
> - **Putting a token and a certificate in one user entry.** The API server may use the certificate and ignore the token.
