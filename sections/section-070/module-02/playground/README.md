# Create And Assign ServiceAccounts — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-070-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (authored with static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
Starfleet workloads run in `starfleet` and `outpost` as the `default`
service account. A `regcred` registry credential Secret exists in `starfleet`.
Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-070-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, the `regcred` Secret and the workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
