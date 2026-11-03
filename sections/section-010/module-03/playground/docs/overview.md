# Discover And Operate With Operators Environment

This ungraded playground is a single-node kind cluster running Kubernetes 1.35. It has one operator. No task is submitted for grading.

## What is in the environment

| Object | Where | What it is |
| --- | --- | --- |
| `hangars.fleet.astrona.io` | cluster | The CRD of the kind `Hangar`: `spec.replicas` (1 to 5) and `spec.image`, a status subresource and the short name `hgr` |
| `hangar-operator` | namespace `fleet-system` | A Deployment that runs a small controller. It lists every `Hangar`, creates a Deployment named `hangar-<name>` that the `Hangar` owns, and writes a `Ready` condition into the status |
| `hangar-operator` | cluster | A service account, a `ClusterRole` and a `ClusterRoleBinding` that give the controller its permissions |
| `starfleet`, `outpost` | cluster | Empty namespaces for your `Hangar` objects |

No `Hangar` exists yet. The module readings create the first one.

Select the private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-010-03)"
kubectl get hangars -A
```

## Ideas to try

- Run `kubectl api-resources --api-group=fleet.astrona.io` and find the kind, its short name and its scope.
- Find the operator without being told where it is: look for pods that use the service account `hangar-operator` and read its logs.
- Create a `Hangar` in `starfleet`, wait for it to become `Ready`, and read the `ownerReferences` of the Deployment it created.
- Change `spec.replicas` and compare `metadata.generation` with `status.observedGeneration`.
- Delete a `Hangar` and watch its Deployment disappear. Repeat with `--cascade=orphan` and find what stays behind.
- Add a finalizer to a `Hangar`, delete it, and find out why it stays in the `Terminating` state. Then remove the finalizer.
- Scale the operator to zero replicas, create a `Hangar`, and read what the API server stores.
- Remove the `create` verb for `deployments` from the `ClusterRole` and read the operator log and the condition of a new `Hangar`.

Destroy the playground when you are done:

```sh
astrona destroy ats-029-playground-010-03
```

The command takes the environment name, not a path. The environment is ungraded, so `astrona submit` does not apply.
