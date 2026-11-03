# Admission Control — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-020-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
namespaces `starfleet` and `outpost` and one busybox Deployment in each. No
`LimitRange`, `ResourceQuota` or admission policy exists. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-03/playground
astrona destroy ats-029-playground-020-03
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Two namespaces and the two Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |

UNTESTED: authored statically, not yet run live.
