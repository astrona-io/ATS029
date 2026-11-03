# Define A CustomResourceDefinition - Playground

- **Slug:** ats-029-playground-010-02
- **Type:** Astrona playground, clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the namespaces `starfleet` and `outpost` and one complete reference CRD, `telemetries.fleet.astrona.io`. No custom resource exists yet and no controller runs.

UNTESTED: authored statically, not yet run live.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/playground
astrona destroy ats-029-playground-010-02
```

`astrona destroy` takes the environment name, not the path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/namespaces.yaml` | The `starfleet` and `outpost` namespaces |
| `manifests/telemetry.yaml` | The reference CRD with schema, defaults, printer columns and a status subresource |
| `docs/overview.md` | What the environment contains and ideas to try |
