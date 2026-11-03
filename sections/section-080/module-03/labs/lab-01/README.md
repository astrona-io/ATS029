---
estimated_duration: 25m
---

# Lab: Fix A Deployment Rejected By Pod Security Admission

Graded lab for the seccomp, host access and Pod Security Admission module. The `outpost` namespace enforces `restricted`, and the `bridge` Deployment uses the host network and a `hostPath` volume, so it has no pod. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate`, `bash -n`, YAML parse). It has not been run on a cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-03/labs/lab-01
astrona destroy ats-029-lab-080-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-namespace-policy-intact.sh` | `outpost` still enforces `restricted` (no lower level, no version pin) and a server-side dry run of a privileged pod fails with `violates PodSecurity` |
| `validate-bridge-available.sh` | One replica is available, and the container name, image and command are unchanged |
| `validate-no-host-access.sh` | No live pod sets `hostNetwork`, `hostPID` or `hostIPC` or mounts a `hostPath` |
| `validate-hardening.sh` | The live process runs as 1000, has seccomp mode 2, an all-zero capability mask and `NoNewPrivs` 1 |
| `validate-writable-paths.sh` | The root filesystem is read-only, `/tmp/state` is `up` and `/work/heartbeat` is fresh |
