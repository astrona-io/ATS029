---
estimated_duration: 25m
---

# Lab: Fix A Hangar That Does Not Reconcile

Graded lab for the operator module. The `hangar-operator` runs, but its `ClusterRole` lacks the `create` verb on Deployments, so the `Hangar` `scout-bay` never reconciles. A second `Hangar`, `old-bay`, is stuck in the `Terminating` state because of a finalizer that nothing handles. The task is in `question.md`; the walkthrough is in `solution.md`.

UNTESTED: authored with static checks only (`astrona validate`, `bash -n`, YAML parse). Not run against a live cluster yet.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-03/labs/lab-01
astrona destroy ats-029-lab-010-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-operator-permission.sh` | The service account `hangar-operator` can create and patch Deployments (`kubectl auth can-i --as`), cannot delete Deployments, read Secrets, create Pods or use a wildcard, and has no binding to `cluster-admin`, `admin` or `edit` |
| `validate-scout-bay-ready.sh` | `scout-bay` has `Ready=True`, `status.observedGeneration` equals `metadata.generation`, and its uid matches the one recorded at the start (not deleted and created again) |
| `validate-owned-by-hangar.sh` | `hangar-scout-bay` has a controller owner reference to the uid of `scout-bay`, two available replicas and a running operator Deployment |
| `validate-old-bay-removed.sh` | `old-bay` no longer exists and the CRD still exists and is established |
| `validate-reconcile-and-cleanup.sh` | A new `Hangar` gets an owned Deployment, a change of `spec.replicas` is applied, and deleting the `Hangar` removes the Deployment |

All five checks fail before any change.
