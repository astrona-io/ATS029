# Create Secrets With kubectl And YAML — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-060-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (authored with static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
`starfleet` namespace has the `scout` Deployment and a Secret named
`scout-legacy`. The `outpost` namespace has the `drifter` Deployment. Nothing
to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-060-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, the `scout` and `drifter` Deployments and the `scout-legacy` Secret |
| `docs/overview.md` | What the environment contains and ideas to try |
