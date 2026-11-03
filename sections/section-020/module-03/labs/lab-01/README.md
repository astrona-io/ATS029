---
estimated_duration: 25m
---

# Lab: Set Container Defaults And Limit Replicas With Admission

Graded lab for the admission control module. The cluster starts with the namespaces `starfleet` and `outpost` and one busybox Deployment in each. The learner creates a `LimitRange` for default container resources, a `ValidatingAdmissionPolicy` that limits replicas, and a binding that enforces it only in `outpost`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-03/labs/lab-01
astrona destroy ats-029-lab-020-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limitrange-defaults.sh` | A server-side dry run of a pod without resources in `outpost` shows the default requests and limits, and the same pod in `starfleet` shows none |
| `validate-replicas-denied.sh` | 5 and 4 replicas are rejected on create, an update of `drifter` to 5 is rejected, and the message comes from a ValidatingAdmissionPolicy (a `Warn`-only binding or a policy without `UPDATE` fails) |
| `validate-policy-scope.sh` | 1 and 3 replicas pass in `outpost`, 5 replicas pass in `starfleet`, and a plain pod passes in `outpost` |
| `validate-drifter-unchanged.sh` | `drifter` and `scout` still exist with one available replica |

The checks about the policy retry for about 30 seconds, because a new binding takes a few seconds to become active.

UNTESTED: authored statically, not yet run live.
