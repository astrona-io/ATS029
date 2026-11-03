---
estimated_duration: 25m
---

# Lab: Consume Secrets In Pods

Graded lab for the Secret consumption module. The `probe` Deployment in `starfleet` keeps its password as a plain value in the pod template, two Secrets exist and nothing uses them, and the `auditor` ServiceAccount has no permissions. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-03/labs/lab-01
astrona destroy ats-029-lab-060-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-password-from-secret.sh` | `DB_PASSWORD` uses `secretKeyRef` `probe-credentials`/`password`, the plain value is gone from the pod template, and the running container has the Secret value |
| `validate-probe-certificate-mount.sh` | `probe-certificate` is mounted at `/etc/probe/tls` with `readOnly: true`, and both files have mode `400` inside the pod |
| `validate-auditor-least-privilege.sh` | `auditor` can `get` only `probe-credentials` (not `probe-certificate`, not `list`, not `delete`, not in another namespace) |
| `validate-secrets-intact.sh` | Neither Secret was edited or deleted, and a `probe` pod is running |

`secrets-intact` passes before any change. The other three fail until the task is done.
