---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Defaults, QoS Classes And Runtime Limits

A quota limits a namespace as a whole. It does not decide what a single container gets, what happens when a container uses more than it asked for, or which pod the cluster stops first when a node runs short. Those decisions come from LimitRange (defaults and per-object limits), from the quality of service (QoS) class that the API server assigns to each pod, and from the node components that enforce limits at runtime.

This module follows one container from admission to the node. You will let a LimitRange fill in missing values and reject values outside a range, read the QoS class of a pod, watch CPU throttling and an out-of-memory kill, and diagnose a pod that stays `Pending` because no node has enough unreserved capacity.

## Goals

- Write a LimitRange with defaults, minimum and maximum values, a limit to request ratio, and limits for pods and volume claims.
- Predict the QoS class of a pod from its resources and read it with `kubectl`.
- Explain what CPU limits and memory limits do at runtime and why the two differ.
- Diagnose `OOMKilled`, `CrashLoopBackOff` and `FailedScheduling` from pod status and events.
- State the order in which the kubelet evicts pods under node pressure.

## Learning objectives

After this module you can:

- Predict the requests and limits that a pod receives from a LimitRange and read the rejection message when a value is out of range.
- Classify a pod as `Guaranteed`, `Burstable` or `BestEffort` and make a Deployment produce a chosen class.
- Tell CPU throttling from an out-of-memory kill, and read the container state that proves which one happened.
- Explain a `Pending` pod with `Insufficient cpu` or `Insufficient memory` and decide which request to change.
- Explain why a `BestEffort` pod is evicted before a `Guaranteed` pod.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl exec`. You should know that a container can declare a resource request and a resource limit, and that a ResourceQuota limits a namespace.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. The cluster has no metrics server, so `kubectl top` does not work.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` (`podinfo`), `probe` (`go-httpbin`) and `shuttle` (`curl`) Deployments with small requests and a memory limit. The Services `scout` and `probe`. No LimitRange and no ResourceQuota |
| `outpost` | The `drifter` client Deployment. No LimitRange and no ResourceQuota |

The parts run in this order: LimitRange, QoS classes, CPU throttling and memory kills, and scheduling and eviction. A summary closes the module.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
