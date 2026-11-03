---
estimated_duration: 35m
---

# Capstone Lab: Right-Size Workloads Under A Namespace Quota

Graded capstone for the resource requirements section. **UNTESTED**: authored with static checks only (`astrona validate`, `bash -n`, YAML parse); it has not been run. It combines memory limits, effective requests of a Pod with a sidecar, the Guaranteed class, LimitRange defaults and a ResourceQuota. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-029-capstone-050
```

Authors prove the reference solution with `astrona test -c .`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-bridge-memory-fixed.sh` | `bridge` has a memory limit between 192Mi and 512Mi and its Pod was not killed for memory |
| `validate-scout-admitted-and-guaranteed.sh` | `scout` Pods exist, are Ready and `Guaranteed`, and every container has equal requests and limits |
| `validate-shuttle-uses-defaults.sh` | `starfleet-defaults` exists with the required values and the `shuttle` Pod carries the defaults |
| `validate-quota-unchanged.sh` | `starfleet-quota` has its original values and the namespace usage is inside it |
| `validate-no-besteffort-and-images.sh` | No Pod is BestEffort, images and the sidecar are unchanged |
