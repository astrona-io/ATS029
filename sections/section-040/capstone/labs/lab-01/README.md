---
estimated_duration: 35m
---

# Capstone Lab: Create, Consume And Change ConfigMaps

Integrated graded lab for the ConfigMaps section. It covers writing immutable ConfigMaps, consuming them as environment variables and files, and changing the configuration through a new versioned ConfigMap and a rollout. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate -c`, `bash -n`, YAML parse). It has not been run on a live cluster.

## Run it

```sh
astrona run -c sections/section-040/capstone/labs/lab-01
astrona submit -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-029-capstone-040
```

Authors prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-configmaps.sh` | `scout-config-v1` (`info`) and `scout-config-v2` (`debug`) exist, are immutable and have the keys `LOG_LEVEL`, `REGION`, `scout.conf` |
| `validate-deployment-references.sh` | The template uses `scout-config-v2` for `configMapKeyRef`, `envFrom` (prefix `SCOUT_`) and the volume, never `scout-config-v1`, and no `subPath` |
| `validate-pod-environment.sh` | Every running pod has `LOG_LEVEL=debug`, `SCOUT_LOG_LEVEL=debug` and `SCOUT_REGION=outpost-7` |
| `validate-pod-files.sh` | In every running pod `/etc/scout` holds only `scout.conf`, with the right content and mode 440 |
| `validate-rollout.sh` | The rollout is complete, two replicas are available and exactly two pods exist |
