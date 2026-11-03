# Users, Groups, Capabilities And Privilege — Playground

- **Slug:** ats-029-playground-080-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED. Written with static checks only (`astrona validate`, `bash -n`, YAML parse).

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The `starfleet`
namespace runs `scout` (podinfo) and `shuttle` (busybox) with no `securityContext`.
Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-080-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | The namespace and the two starting Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |
