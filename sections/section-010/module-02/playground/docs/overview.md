# Define A CustomResourceDefinition Environment

This ungraded playground is a single-node kind cluster running Kubernetes 1.35. `kubectl` is available and the private kubeconfig of the environment is selected for you. No controller runs, so every custom resource you create is only validated and stored. Nothing reconciles it. No task is submitted for grading.

## What is in the environment

| Object | Where | What it is |
| --- | --- | --- |
| `telemetries.fleet.astrona.io` | cluster | A complete CustomResourceDefinition (CRD): a schema with `required`, `enum`, `minimum` and `default`, a status subresource, printer columns and the short name `tlm` |
| `starfleet` | cluster | An empty namespace for your custom resources |
| `outpost` | cluster | A second empty namespace for copies of resources |

No `Telemetry` exists yet. The module readings create the first one.

Select the private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-playground-010-02)"
kubectl get telemetries -A
```

## Ideas to try

- Run `kubectl explain telemetry.spec --api-version=fleet.astrona.io/v1` and compare each field with the CRD YAML from `kubectl get crd telemetries.fleet.astrona.io -o yaml`.
- Create a `Telemetry` with `level: fatal`, then with `intervalSeconds: 0`, then without `source`. Read each error message.
- Create a `Telemetry` with an extra field `colour: red`. Then repeat the command with `--validate=false` and read the object back. Find out where the field went.
- Write your own CRD for a kind such as `Dock`, apply it, and wait for `condition=Established`.
- Delete your own CRD and check what happens to its custom resources.
- Use `kubectl patch --subresource=status` on a `Telemetry` and compare it with a patch of the whole object.

Destroy the playground when you are done:

```sh
astrona destroy ats-029-playground-010-02
```

The command takes the environment name, not a path. The environment is ungraded, so `astrona submit` does not apply.
