# Overview: Admission Control (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Apply limits and policies, break them on purpose, run `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it with the cluster administrator credentials.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | A `scout` Deployment running `busybox:1.37.0`, with no resource requests or limits |
  | `outpost` | A `drifter` Deployment running `busybox:1.37.0`, with no resource requests or limits |

  No `LimitRange`, `ResourceQuota` or admission policy exists.

## Ideas to try

- Read `spec.serviceAccountName` and the volumes of the `scout` pod and find what the API server added that the Deployment never contained.
- Create a `LimitRange` in `outpost`, then create a pod and read its resources with `kubectl get pod -o yaml`.
- Create a `ResourceQuota` that allows two pods in `outpost`, scale `drifter` to three and read the `FailedCreate` event on the ReplicaSet.
- Run `kubectl apply --dry-run=server` on a manifest that a policy rejects and compare it with `--dry-run=client`.
- Create a `ValidatingAdmissionPolicy` with a `Warn` action first, then change the binding to `Deny`.
