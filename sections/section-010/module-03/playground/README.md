# Discover And Operate With Operators - Playground

- **Slug:** ats-029-playground-010-03
- **Type:** Astrona playground, clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the `Hangar` CRD (`hangars.fleet.astrona.io`) and a working operator, `hangar-operator`, in the namespace `fleet-system`. The operator turns each `Hangar` into a Deployment that the `Hangar` owns and writes a `Ready` condition into the status. No `Hangar` exists at the start.

UNTESTED: authored statically, not yet run live.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-03/playground
astrona destroy ats-029-playground-010-03
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/namespaces.yaml` | The `starfleet` and `outpost` namespaces |
| `manifests/hangar-crd.yaml` | The `Hangar` CRD |
| `manifests/hangar-operator.yaml` | The operator: Python controller in a ConfigMap, service account, ClusterRole, ClusterRoleBinding and Deployment |
| `docs/overview.md` | What the environment contains and ideas to try |
