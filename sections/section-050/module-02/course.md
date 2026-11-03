---
draft: true
exam_objectives:
- Define resource requirements
---
# Requests, Limits And Quality Of Service

A container that has no resource settings can use as much central processing unit (CPU) and memory as the node allows, and the scheduler knows nothing about its needs. A container with wrong settings is worse: it is killed for memory, slowed down by a CPU limit, or never scheduled at all. This module teaches the mechanism behind the two fields that every Kubernetes application developer must set, `resources.requests` and `resources.limits`, and how Kubernetes turns them into placement, enforcement and eviction decisions.

Keep one sentence in mind for this module: **the scheduler reads requests, the kubelet and the Linux kernel enforce limits, and the quality of service class decides who is stopped first when a node runs short.** You will read the real kernel settings behind a limit, cause a memory kill and CPU throttling on purpose, predict a quality of service class from a Pod specification, read how a node adds up the requests of its Pods, and calculate the effective request of a Pod that has init containers and a sidecar.

The module has three parts. **CPU And Memory Requests And Limits** explains the units and shows who enforces what. **Quality Of Service And Node Allocation** explains the three classes and how to read a node's allocation. **Init And Sidecar Container Resources** explains how the effective Pod request is calculated.

## Learning objectives

After this module you can:

- Write CPU and memory quantities in the correct units and avoid the `m` and `M` mistakes.
- Explain which component uses a request and which component enforces a limit.
- Tell a CPU throttling problem from an out-of-memory (OOM) kill and find each one with `kubectl`.
- Predict the quality of service (QoS) class of a Pod and read it from `status.qosClass`.
- Read the `Capacity`, `Allocatable` and `Allocated resources` sections of `kubectl describe node`.
- Calculate the effective request of a Pod with init containers and a sidecar container.

## Before you start

You need Kubernetes basics: Pods, Deployments, namespaces and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl exec`. You do not need any extra tool. The metrics server is not installed in the playground, so `kubectl top` is explained but does not return data there.

Your playground is a single-node `kind` cluster running Kubernetes 1.35:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | Three Deployments with three different resource settings. `scout` sets equal requests and limits for CPU and memory. `probe` sets requests below its limits. `shuttle` sets no resources at all |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
