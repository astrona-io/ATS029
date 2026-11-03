---
estimated_duration: 30m
---

# Capstone: ServiceAccounts

Graded capstone for the ServiceAccounts section. **Status: UNTESTED** (authored with static checks only; the reference solution has not been run). It combines removing an over-privileged default account, creating and assigning accounts, `imagePullSecrets`, switching off a token mount and granting a Role to a ServiceAccount. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/capstone/labs/lab-01
astrona destroy ats-029-capstone-070
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-default-unprivileged.sh` | `default` in `starfleet` cannot list Secrets across the cluster, no ClusterRoleBinding names it, and the account still exists |
| `validate-bridge-lists-pods.sh` | A real request from the `bridge` pod returns HTTP 200 for pods in `starfleet` |
| `validate-bridge-least-privilege.sh` | HTTP 403 for Secrets from the pod, and `can-i` says no for write verbs and for other namespaces |
| `validate-bridge-pull-secret.sh` | The `bridge` account lists `regcred` and every running `bridge` pod has it |
| `validate-scout-no-token.sh` | The `scout` account has `automountServiceAccountToken: false` and the running `scout` pods have no token volume |
| `validate-scout-serves.sh` | `bridge` gets HTTP 200 from the `scout` Service |
