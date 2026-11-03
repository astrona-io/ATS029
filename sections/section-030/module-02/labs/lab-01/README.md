---
estimated_duration: 25m
---

# Lab: Fit A Workload Into A Namespace Quota

Graded lab for the ResourceQuota module. The `starfleet` namespace starts with `scout`, a three-replica `shuttle` Deployment with no requests or limits, and no quota. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** This lab was authored with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been run on a live cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-029-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-quota-values.sh` | `fleet-budget` exists with exactly the seven hard values (units are normalised, a raised quota fails) |
| `validate-shuttle-fits-quota.sh` | `shuttle` has 3 replicas, all available, every live pod declares 200m/128Mi requests and 400m/256Mi limits, and `scout` is still available |
| `validate-over-budget-rejected.sh` | A server-side dry run of a pod requesting 2 CPUs fails with `exceeded quota`; a small pod is admitted |
| `validate-storage-budget.sh` | `logbook` is 2Gi `ReadWriteOnce`; a second 2Gi claim fails with `exceeded quota`; a 1Gi claim is admitted |

The quota checks fail before any change because `fleet-budget` does not exist. A learner who only sets requests fails `shuttle-fits-quota`, and a learner who raises the quota to fit fails `quota-values`.
