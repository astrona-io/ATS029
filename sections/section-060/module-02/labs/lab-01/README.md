---
estimated_duration: 25m
---

# Lab: Create Secrets With kubectl

Graded lab for the Secret creation module. The `starfleet` namespace starts with a `scout` Deployment whose pod cannot start, because the Secret it reads does not exist. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-02/labs/lab-01
astrona destroy ats-029-lab-060-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-credentials.sh` | `scout-credentials` has the key `api-key` with the exact value `ion-4471` (no trailing newline), and the running `scout` container sees it as `API_KEY` |
| `validate-bridge-settings.sh` | `bridge-settings` has exactly the keys `REGION` and `TIER` with the right values (a `--from-file` Secret fails) |
| `validate-bridge-registry.sh` | `bridge-registry` has type `kubernetes.io/dockerconfigjson` and the right server, user name and password |
| `validate-scout-credentials-immutable.sh` | `scout-credentials` has `immutable: true` and a server-side dry run of a change is rejected |

All four checks fail before any change, because none of the Secrets exist.
