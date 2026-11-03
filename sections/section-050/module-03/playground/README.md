# Namespace Policy, Storage And Right-Sizing — Playground

- **ID:** ats-029-playground-050-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). `outpost` has a
LimitRange and a ResourceQuota. `starfleet` has a healthy `scout`, a `bridge` that is killed for
memory and a `shuttle` that stays Pending. The metrics server is not installed.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-050-03
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/policy.yaml` | Namespaces, LimitRange `outpost-defaults`, ResourceQuota `outpost-quota` |
| `manifests/workloads.yaml` | The four Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |
