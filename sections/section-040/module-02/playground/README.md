# Creating ConfigMaps — Playground

- **Slug:** ats-029-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED. Authored with static checks only.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
`starfleet` namespace holds a `viewer` Deployment with one busybox pod. No
ConfigMaps of your own exist. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-040-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | The `starfleet` namespace and the `viewer` Deployment |
| `docs/overview.md` | What the environment contains and ideas to try |
