---
draft: true
exam_objectives:
- Define resource requirements
---
# Namespace Policy, Storage And Right-Sizing

A Pod specification is only one of the places where resource numbers come from. The namespace can add defaults, set minimum and maximum values, and cap the total that all Pods may request. The node tracks more than CPU and memory: it also tracks temporary disk space and any custom resource that an administrator advertises. This module covers these extra sources and limits, and then puts everything together in a method for finding and fixing a workload whose resource settings are wrong.

Keep one sentence in mind for this module: **the API server rejects or changes a Pod at admission time according to the namespace policy, the scheduler places it by its requests, and the kubelet evicts or kills it at run time by its limits, so every failure has a different place to look.** You will read a LimitRange and a ResourceQuota, watch a Deployment lose Pods to a quota, fill a Pod's ephemeral storage until it is evicted, advertise and request an extended resource, set resources at Pod level, and diagnose broken Deployments from their symptoms.

The module has three parts. **LimitRange And ResourceQuota** explains namespace defaults, limits and totals. **Ephemeral Storage, Extended Resources And Pod-Level Resources** explains the other resource types and the Pod-wide settings. **Right-Sizing And Fixing Failing Workloads** gives a diagnosis method and the commands to apply a fix.

## Learning objectives

After this module you can:

- Explain how a LimitRange sets defaults, minimums and maximums, and how a ResourceQuota caps a namespace.
- Tell an admission rejection from a Pending Pod and from a ReplicaSet that cannot create Pods.
- Set ephemeral storage requests and limits and explain what the kubelet does when a Pod goes over its limit.
- Request an extended resource and read the scheduling result.
- Set resources at Pod level and explain how they relate to container resources.
- Diagnose a Pending, OOMKilled or rejected workload and fix it with `kubectl set resources`.

## Before you start

You need Kubernetes basics (Pods, Deployments, namespaces), the difference between a request and a limit, and the commands `kubectl get`, `kubectl describe`, `kubectl apply` and `kubectl edit`. The metrics server is not installed in the playground.

Your playground is a single-node `kind` cluster running Kubernetes 1.35:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | No namespace policy. `scout` runs normally. `bridge` is killed for memory and `shuttle` stays Pending, both on purpose |
| `outpost` | A LimitRange `outpost-defaults` and a ResourceQuota `outpost-quota`. The `drifter` Deployment runs here |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
