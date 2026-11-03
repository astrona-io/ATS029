---
estimated_duration: 30m
---

# Capstone: Application Security

Graded integration lab for the whole section. The `starfleet` namespace enforces `restricted`, and the `probe` Deployment is privileged, runs as root on the host network with a `hostPath` volume, so it has no pod. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate`, `bash -n`, YAML parse). It has not been run on a cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/capstone/labs/lab-01
astrona destroy ats-029-capstone-080
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-namespace-policy-intact.sh` | `starfleet` still enforces `restricted` and a server-side dry run of a privileged pod fails with `violates PodSecurity` |
| `validate-probe-available.sh` | One replica is available, with the original container names, images and commands |
| `validate-no-host-access-and-sysctl.sh` | No host namespace, no `hostPath`, and the safe sysctl is set in the spec and in the kernel |
| `validate-identity-and-volume.sh` | `id` output of both containers, `fsGroup` 4000, the group of `/shared` and the owner of the files in it |
| `validate-privilege-and-filesystem.sh` | Not privileged, no added capability, an all-zero capability mask, `NoNewPrivs` 1, seccomp mode 2, a read-only root filesystem and `/tmp/state` written |
