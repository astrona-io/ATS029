---
estimated_duration: 20m
---

# Lab: ServiceAccount Tokens And API Access

Graded lab for the ServiceAccount tokens module. **Status: UNTESTED** (authored with static checks only; the reference solution has not been run). The `shuttle` pod in `starfleet` runs as the `default` account and gets `403 Forbidden` when it lists pods. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-03/labs/lab-01
astrona destroy ats-029-lab-070-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-shuttle-account.sh` | Every running `shuttle` pod uses the `shuttle` account |
| `validate-shuttle-lists-pods.sh` | A real request from inside the `shuttle` pod, with its mounted token, returns HTTP 200 for the pod list |
| `validate-shuttle-no-secrets.sh` | The same request for Secrets returns HTTP 403, and `can-i` agrees |
| `validate-shuttle-read-only.sh` | `can-i` says no to `create`, `delete`, `update` and `patch` on pods |
| `validate-scope.sh` | The `shuttle` account cannot list pods in `outpost`, and the `default` account in `starfleet` still cannot list pods |
