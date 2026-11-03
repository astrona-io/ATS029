---
estimated_duration: 25m
---

# Lab: Consume ConfigMaps In A Deployment

Graded lab for the "Consuming ConfigMaps" module. The `probe` Deployment in `starfleet` uses a fixed `LOG_LEVEL`, and the ConfigMap `probe-settings` is not used yet. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate -c`, `bash -n`, YAML parse). It has not been run on a live cluster.

## Run it

```sh
astrona run -c sections/section-040/module-03/labs/lab-01
astrona submit -c sections/section-040/module-03/labs/lab-01
astrona destroy ats-029-lab-040-03
```

Authors prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-env-key-ref.sh` | `LOG_LEVEL` uses `configMapKeyRef` to `probe-settings` key `LOG_LEVEL` and has no fixed value |
| `validate-envfrom-prefix.sh` | The template has `envFrom` with prefix `SETTING_`, and every running pod has `SETTING_REGION=outpost-7` and `SETTING_LOG_LEVEL=debug` |
| `validate-mounted-file.sh` | No `subPath`; in every running pod `/etc/probe` holds only `probe.conf`, with the content `retries=3` and mode 444 |
| `validate-rollout-complete.sh` | The rollout is complete, two replicas are available and `LOG_LEVEL` in every pod is `debug`, not the old `warn` |
| `validate-configmap-unchanged.sh` | `probe-settings` still has its original three keys and values |

All checks fail before any change except `validate-configmap-unchanged.sh`, which passes until someone edits the ConfigMap.
