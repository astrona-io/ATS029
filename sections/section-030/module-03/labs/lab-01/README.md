---
estimated_duration: 25m
---

# Lab: Set Namespace Defaults And Fix An OOM-Killed Workload

Graded lab for the LimitRange and QoS module. The `outpost` namespace starts with a `drifter` Deployment that declares no resources, a `beacon` Deployment that is killed for exceeding its memory limit, and no LimitRange. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-03/labs/lab-01
astrona destroy ats-029-lab-030-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limitrange-values.sh` | `outpost-limits` has a `Container` entry with exactly the requested default, defaultRequest, min, max and CPU ratio (a raised maximum fails) |
| `validate-drifter-defaults.sh` | `drifter` is available, its live pod has 100m/128Mi requests and 200m/256Mi limits, and the Deployment template declares no resources |
| `validate-beacon-guaranteed.sh` | After a 20 second wait, `beacon` has one live pod that is `Running`, `Guaranteed` and has 0 restarts |
| `validate-limits-enforced.sh` | Server-side dry runs: a 1Gi limit is rejected by the maximum, a ratio of 8 is rejected, and a pod with no resources receives the defaults |

All checks fail before any change. A learner who writes the values into `drifter` fails `drifter-gets-defaults`, and one who sets only a larger limit on `beacon` fails the `Guaranteed` test.
