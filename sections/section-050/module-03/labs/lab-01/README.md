---
estimated_duration: 25m
---

# Lab: Apply Namespace Defaults And Quota

Graded lab for the namespace policy module. **UNTESTED**: authored with static checks only (`astrona validate`, `bash -n`, YAML parse); it has not been run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-029-lab-050-03
```

Authors prove the reference solution with `astrona test -c .`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limitrange-defaults.sh` | `outpost-defaults` has the required `default`, `defaultRequest` and `max` values for CPU, memory and ephemeral storage |
| `validate-drifter-uses-defaults.sh` | The `drifter` Deployment sets no resources itself, has 2 ready Pods, and the Pods carry the default values |
| `validate-beacon-within-maximum.sh` | `beacon` is Running with a CPU limit of at most 500m and a memory limit of at most 256Mi |
| `validate-quota-tracks-ephemeral-storage.sh` | The quota keeps its old values and adds the two ephemeral storage caps |
| `validate-pods-carry-ephemeral-requests.sh` | All active Pods in `outpost` have ephemeral storage requests and limits |
