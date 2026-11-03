# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the fields of a LimitRange (`default`, `defaultRequest`, `min`, `max`, `maxLimitRequestRatio`), the three QoS classes, and how to read `OOMKilled` from a pod.

The lab starts a single-node kind cluster (Kubernetes 1.35) with two workloads in the `outpost` namespace. The commands for the lab are in the README of this folder.
