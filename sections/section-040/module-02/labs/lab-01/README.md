---
estimated_duration: 20m
---

# Lab: Create ConfigMaps From Different Sources

Graded lab for the "Creating ConfigMaps" module. The `starfleet` namespace starts with one ConfigMap, `probe-settings`. The task is in `question.md`; the walkthrough is in `solution.md`.

**Status: UNTESTED.** Authored with static checks only (`astrona validate -c`, `bash -n`, YAML parse). It has not been run on a live cluster.

## Run it

```sh
astrona run -c sections/section-040/module-02/labs/lab-01
astrona submit -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-029-lab-040-02
```

Authors prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-env.sh` | `scout-env` has exactly the keys `MODE` and `RETRIES` with the values `fast` and `3` (rejects `--from-file`) |
| `validate-scout-files.sh` | `scout-files` has exactly `app.properties` (two lines) and `banner.txt` (rejects the default key name) |
| `validate-scout-locked.sh` | `scout-locked` has `immutable: true`, only `LOG_LEVEL=warn`, and the API server refuses a server-side dry-run patch |
| `validate-probe-settings.sh` | `probe-settings` has `LOG_LEVEL=info`, keeps `probe.conf` and is not immutable (rejects `kubectl replace` with a partial file) |

All four checks fail before any change, because the three new ConfigMaps do not exist and `LOG_LEVEL` is `trace`.
