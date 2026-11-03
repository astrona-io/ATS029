# Consume Secrets In Pods — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-060-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (authored with static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
`starfleet` namespace has three Secrets (`bridge-credentials`,
`bridge-certificate`, `bridge-registry`), the service accounts `scout`,
`probe` and `auditor`, and the Deployments `scout` and `probe`, which use no
Secrets yet. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-060-03
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, Secrets, service accounts and the two Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |
