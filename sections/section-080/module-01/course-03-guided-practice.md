---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Run Non-Root With A Read-Only Root Filesystem

The Pod declares a numeric non-root identity, drops capabilities and provides one writable emptyDir. You will compare an allowed scratch write with a denied write to the root filesystem. This demonstrates distinct security-context mechanisms without claiming that they isolate every application risk.

Use the module playground and its private kubeconfig. The context check below prevents commands from being directed at an unrelated cluster. The helper retries a command for a bounded interval after controller or policy changes; it cannot turn a persistent failure into success. Read the actual errors when the interval expires.

<!-- astrona:playground:renew -->

For a timed catalog session, renew this module before continuing. Skip renewal for an untimed local author run:

```sh
astrona run renew astrona-io/ATS029/section-080/module-01/playground
```

Select the module environment and define a bounded retry helper:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-080-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-080-01"
kubectl -n starfleet get pods
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
```

Save the complete Pod with workload-level identity and container-level restrictions.

Save this as `pod-restricted-reader.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-reader
  namespace: starfleet
spec:
  containers:
  - name: reader
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: scratch
      mountPath: /scratch
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - name: scratch
    emptyDir: {}
```

Apply or use the saved input, then check the result:

```sh
kubectl apply -f pod-restricted-reader.yaml
kubectl -n starfleet wait --for=condition=Ready pod/restricted-reader --timeout=120s
kubectl -n starfleet exec restricted-reader -- id
```

The workload identity controls the process user and shared-volume group. It is not the same thing as the Kubernetes ServiceAccount or an external business identity.

Write to the declared scratch mount, then deliberately test the protected filesystem path.

```sh
kubectl -n starfleet exec restricted-reader -- sh -c 'printf allowed > /scratch/result; cat /scratch/result'
if kubectl -n starfleet exec restricted-reader -- sh -c 'printf denied > /root-file'; then printf 'Root filesystem unexpectedly writable\n' >&2; exit 1; fi
```

A scratch write demonstrates the intended writable mount. The rejected root write is a separate check; it does not mean every path is unwritable or that every Linux privilege has been removed.

Inspect the accepted settings and process evidence.

```sh
kubectl -n starfleet get pod restricted-reader -o yaml
kubectl -n starfleet exec restricted-reader -- cat /proc/1/status
```

Read the configured capability and seccomp requirements alongside process evidence. A seccomp profile constrains system calls according to its policy, not application authorization or network encryption.

Least privilege combines compatible identity, filesystem, capabilities and syscall policy. A setting can prevent an application from starting if its runtime contract needs a forbidden operation. Diagnose that contract rather than immediately enabling privileged mode or removing every restriction.

## Common pitfalls

> [!WARNING]
> Keep the selected module context and inspect the observed outcome. Resource acceptance does not establish readiness or a successful request. Reset this isolated environment if earlier experiments changed the required starting state.
