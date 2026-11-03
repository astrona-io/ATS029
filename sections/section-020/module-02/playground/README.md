# Authentication And kubeconfig — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-029-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
namespaces `starfleet` and `outpost`, two busybox Deployments and the
ServiceAccount `shuttle`. Nothing to submit. You need `openssl` on the host.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-02/playground
astrona destroy ats-029-playground-020-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/outpost.yaml` | Namespaces, the ServiceAccount and the two Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |

UNTESTED: authored statically, not yet run live.
