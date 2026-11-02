---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Consume A Secret Without Printing It Solution

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-060-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-060-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.

## Inspect And Explain

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Inspect the relevant evidence:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get deployment probe -o yaml
```

A Secret stores sensitive configuration but its encoded data is not encryption. The kubelet delivers the referenced key into the environment or a volume. A comparison can verify both delivery paths without printing the value. Use only the disposable value supplied by this task.


Save this as `secret-practice-token.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: practice-token
  namespace: starfleet
type: Opaque
stringData:
  token: disposable-example
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-consumer
  namespace: starfleet
spec:
  restartPolicy: Never
  containers:
  - name: reader
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    env:
    - name: PRACTICE_TOKEN
      valueFrom:
        secretKeyRef:
          name: practice-token
          key: token
    volumeMounts:
    - name: secret
      mountPath: /credentials
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: practice-token
```

Apply the required change:

```sh
kubectl apply -f secret-practice-token.yaml
```

## Verify The Result

Observe the actual result. A denied-request command returns a nonzero status when the denial works. Run denial checks separately from a shell sequence that stops on the first nonzero status.

```sh
kubectl -n starfleet wait --for=condition=Ready pod/secret-consumer --timeout=180s
kubectl -n starfleet exec secret-consumer -- sh -c 'test -n "$PRACTICE_TOKEN" && test "$PRACTICE_TOKEN" = "$(cat /credentials/token)"'
```

Create Opaque Secret `practice-token` with disposable key `token: disposable-example`. Create Pod `secret-consumer` with required environment variable `PRACTICE_TOKEN` from that Secret key and a read-only Secret volume at `/credentials`. Its process must verify a nonempty environment value matching the mounted file. Do not put credentials in the Pod command or print the value.

After recording the result, remove this independent lab with `astrona destroy ats-029-lab-060-01-01`.

## Common pitfalls

> [!WARNING]
> Use only the supplied disposable value. Keep a required key reference and read-only volume; a literal Pod environment value bypasses the Secret. Verify equality without printing credentials.
