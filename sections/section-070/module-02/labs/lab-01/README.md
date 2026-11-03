---
estimated_duration: 20m
---

# Lab: Create And Assign ServiceAccounts

Graded lab for the ServiceAccount creation module. **Status: UNTESTED** (authored with static checks only; the reference solution has not been run). In `starfleet`, `scout`, `probe` and `shuttle` run as the `default` account with a mounted token. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-02/labs/lab-01
astrona destroy ats-029-lab-070-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-account.sh` | The `scout` ServiceAccount exists and has `automountServiceAccountToken: false` |
| `validate-scout-pods.sh` | Every running `scout` pod uses the `scout` account and has no token volume |
| `validate-probe-pull-secret.sh` | The `probe` account lists `regcred`, and every running `probe` pod has `regcred` in its `imagePullSecrets` and uses the `probe` account |
| `validate-probe-token.sh` | Running `probe` pods still have a token volume (the mount was not switched off) |
| `validate-scout-serves.sh` | `shuttle` gets HTTP 200 from the `scout` Service |
