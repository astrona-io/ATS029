---
estimated_duration: 30m
---

# Capstone: Requests, Limits And Quotas

Graded integration lab for the whole section. The `starfleet` namespace starts with a `probe` Deployment that declares no resources, a `bridge` Deployment that is killed for exceeding its memory limit, and neither a LimitRange nor a ResourceQuota. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-029-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limitrange-values.sh` | `starfleet-limits` has a `Container` entry with exactly the requested default, defaultRequest, min and max |
| `validate-quota-values.sh` | `starfleet-budget` has exactly the requested hard values (a raised quota fails) |
| `validate-probe-defaults.sh` | `probe` has three available replicas whose live pods carry the defaults, and the template declares no resources |
| `validate-bridge-guaranteed.sh` | After a 20 second wait, `bridge` has one live pod that is `Running`, `Guaranteed` and has 0 restarts |
| `validate-budget-enforced.sh` | Server-side dry runs: a 512Mi request is refused by the quota, a 1Gi limit is refused by the maximum, and a pod with no resources receives the defaults |

All checks fail before any change.
