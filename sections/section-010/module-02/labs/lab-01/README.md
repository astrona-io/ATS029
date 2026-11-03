---
estimated_duration: 25m
---

# Lab: Register A Beacon CustomResourceDefinition

Graded lab for the CRD definition module. The cluster starts with two empty namespaces. The learner writes a CRD with scope, version, validation, defaults, printer columns and a status subresource, then creates one custom resource. The task is in `question.md`; the walkthrough is in `solution.md`.

UNTESTED: authored with static checks only (`astrona validate`, `bash -n`, YAML parse). Not run against a live cluster yet.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-029-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-crd-registered.sh` | The CRD is `Established`; name, kind, plural, short name, scope `Namespaced`, version `v1` served and stored, status subresource on |
| `validate-schema-rules.sh` | Server-side dry runs: a missing `frequencyMhz`, `0`, `1001` and `mode: chirp` are rejected; a valid `Beacon` is accepted and gets `mode: steady` |
| `validate-unknown-fields-pruned.sh` | A dry run with strict validation off stores no extra field, and the schema has no `x-kubernetes-preserve-unknown-fields` |
| `validate-printer-columns.sh` | The CRD has the columns `Frequency` (integer) and `Mode`, and `kubectl get beacons` prints them |
| `validate-scout-beacon.sh` | `scout-beacon` in `starfleet` has `frequencyMhz: 120` and `mode: pulse` and is reachable with the short name |

All checks fail before any change, because the Beacon type does not exist.
