# Enforce Namespace Budgets With ResourceQuota — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (authored with static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
Starfleet workloads `scout`, `probe` and `shuttle` run in `starfleet`, and
`drifter` runs in `outpost`. Every container sets small requests and a memory
limit. No ResourceQuota and no LimitRange exist. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces and the example workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
