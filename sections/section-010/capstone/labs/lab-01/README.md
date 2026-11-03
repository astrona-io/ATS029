---
estimated_duration: 40m
---

# Capstone: Repair A Hangar API And Its Operator

Graded integration lab for the whole section. The `Hangar` CustomResourceDefinition has no status subresource, no status schema, no limits on replicas and no printer columns. The `hangar-operator` lacks the `create` verb on Deployments, so `scout-bay` never reconciles, and `old-bay` is held by a finalizer that nothing handles. The task is in `question.md`; the walkthrough is in `solution.md`.

UNTESTED: authored with static checks only (`astrona validate`, `bash -n`, YAML parse). Not run against a live cluster yet.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-029-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-crd-schema.sh` | Version `v1` enables the status subresource and declares `observedGeneration`, `readyReplicas` and `conditions`; server-side dry runs reject `spec.replicas` 0 and 9 and accept 1 and 5 |
| `validate-printer-columns.sh` | `kubectl get hangars` shows `REPLICAS` and `READY`, the columns read the right fields, and `scout-bay` shows `True` |
| `validate-operator-permission.sh` | The service account `hangar-operator` can create and patch Deployments, cannot delete Deployments, read Secrets, create Pods or use a wildcard, and has no binding to `cluster-admin`, `admin` or `edit` |
| `validate-scout-bay-ready.sh` | `scout-bay` has `Ready=True`, `observedGeneration` equals `generation`, its uid is unchanged, and `hangar-scout-bay` has a controller owner reference and two available replicas |
| `validate-old-bay-removed.sh` | `old-bay` no longer exists and the CRD still exists and is established |
| `validate-reconcile-and-cleanup.sh` | A new `Hangar` gets an owned Deployment, a change of `spec.replicas` is applied, its status follows the new generation, and deleting the `Hangar` removes the Deployment |

All six checks fail before any change. The files in `solution/` are used only by `astrona test`.
