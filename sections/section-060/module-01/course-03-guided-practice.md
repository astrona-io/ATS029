---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Consume A Disposable Secret Without Printing Its Value

The exercise uses a disposable non-production value and demonstrates two consumption paths. You will create a Secret, mount it and expose one key as an environment value. Checks report presence and length without echoing the credential. Base64 representation is not encryption or permission enforcement.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-060/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-060-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-060-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Create the practice Secret with a harmless value, then save its consumer Pod. The key and reference names must agree exactly.

Save this as `pod-secret-consumer.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-consumer
  namespace: starfleet
spec:
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

Apply or use the saved input, then check the result:

```sh
kubectl -n starfleet create secret generic practice-token --from-literal=token=disposable-example
kubectl apply -f pod-secret-consumer.yaml
kubectl -n starfleet wait --for=condition=Ready pod/secret-consumer --timeout=120s
```

Do not substitute a real token into a reusable exercise or shell history. The fixture demonstrates the contract without granting external authority.

Check that both consumption paths have content without printing the value.

```sh
kubectl -n starfleet exec secret-consumer -- sh -c 'test -n "$PRACTICE_TOKEN"; test -s /credentials/token; wc -c < /credentials/token'
kubectl -n starfleet describe pod secret-consumer
```

Length and reference evidence are narrower than proving an external service accepts a credential. Access to read the Secret or execute in the consumer remains security-relevant.

Inspect object metadata only and remove the consumer before the Secret.

```sh
kubectl -n starfleet get secret practice-token -o jsonpath='{.metadata.name}{" "}{.type}{"\n"}'
kubectl -n starfleet delete pod secret-consumer
kubectl -n starfleet delete secret practice-token
```

Deleting the object does not retract values already copied to processes, logs or external systems. Production rotation needs the credential issuer and consuming application contract.

Treat delivery, confidentiality and external permission as separate responsibilities. Avoid full data dumps as a routine check. This practice verifies references and consumption while preserving the habit that sensitive values do not belong in ordinary diagnostic output.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
