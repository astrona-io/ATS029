---
estimated_duration: 30m
---

# Capstone: Create & Consume Secrets

Graded integration lab for the whole section. The `bridge` Deployment in `starfleet` holds an old password as a plain value, the Secret `bridge-credentials` holds the same old password, no registry Secret exists, and the `auditor` ServiceAccount has no permissions. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/capstone/labs/lab-01
astrona destroy ats-029-capstone-060
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-secrets-created-and-rotated.sh` | `bridge-credentials` has the exact password `Pulsar-2026` and still has its username; `bridge-registry` has type `kubernetes.io/dockerconfigjson` and the right login |
| `validate-bridge-env-from-secret.sh` | `BRIDGE_PASSWORD` uses `secretKeyRef`, no plain password remains in the pod template, and the running container holds the rotated value (a Secret update without a rollout fails) |
| `validate-bridge-credentials-volume.sh` | Only the `password` file is mounted at `/etc/bridge/credentials`, read-only, with mode `400`, and holds the rotated value |
| `validate-bridge-pull-secret.sh` | Every `bridge` pod lists `bridge-registry` in `imagePullSecrets` |
| `validate-auditor-least-privilege.sh` | `auditor` can `get` only `bridge-credentials` (not `bridge-registry`, not `list`, not `update`, not in another namespace) |

All five checks fail before any change.
