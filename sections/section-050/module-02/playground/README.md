# Requests, Limits And Quality Of Service — Playground

- **ID:** ats-029-playground-050-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** UNTESTED (static checks only)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The `starfleet`
namespace runs `scout` (Guaranteed), `probe` (Burstable) and `shuttle` (BestEffort).
The metrics server is not installed, so `kubectl top` does not return data.

## Run it

```sh
astrona run -c .
astrona destroy ats-029-playground-050-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | The namespace and the three Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |
