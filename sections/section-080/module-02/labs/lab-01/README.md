---
estimated_duration: 25m
---

# Lab: Fix User, Group, Volume Ownership And Privilege

Graded lab for the identity and capabilities module. The `shuttle` Deployment in `starfleet` starts with a privileged container, root users and no volume group. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate`, `bash -n`, YAML parse). It has not been run on a cluster.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-02/labs/lab-01
astrona destroy ats-029-lab-080-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-no-privilege.sh` | Every live pod has no privileged container, `allowPrivilegeEscalation: false`, `drop: ["ALL"]`, no added capability, and an all-zero effective capability mask |
| `validate-identity.sh` | Pod-level user 1500 and group 3000, container-level user 2500 for `relay`, and the real `id` output in both containers |
| `validate-volume-group.sh` | Pod-level `fsGroup` 4000, `/data` has group 4000 and `/data/heartbeat` is owned by `1500:4000` |
| `validate-shuttle-running.sh` | One replica is available, names and images are unchanged, and the heartbeat file is fresh |
