---
estimated_duration: 25m
---

# Lab: Fix Resource Settings And Quality Of Service

Graded lab for the requests, limits and quality of service module. **UNTESTED**: authored with static checks only (`astrona validate`, `bash -n`, YAML parse); it has not been run. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-029-lab-050-02
```

Authors prove the reference solution with `astrona test -c .`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-shuttle-memory-fixed.sh` | `shuttle` has a memory limit between 192Mi and 512Mi, request not above limit, and its running Pod has no `OOMKilled` in its last state |
| `validate-scout-guaranteed.sh` | Every `scout` Pod is `Guaranteed`, init container and sidecar have equal requests and limits |
| `validate-probe-scheduled.sh` | `probe` has a CPU request below one core and a Ready Pod |
| `validate-resources-not-removed.sh` | All containers of all three Deployments keep CPU and memory requests |
| `validate-workloads-keep-images.sh` | Images and replica counts are unchanged |
