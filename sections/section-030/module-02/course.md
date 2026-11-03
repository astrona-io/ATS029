---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Enforce Namespace Budgets With ResourceQuota

A team shares one cluster with other teams. Without a limit, one namespace can create so many pods, volumes and objects that the others cannot work. A ResourceQuota is the object that sets a hard ceiling for one namespace, and the API server enforces that ceiling every time someone creates or changes an object.

This module goes deep on ResourceQuota. You will set compute, object count and storage quotas, read the used and hard values, trigger the two admission errors you must recognise (exceeded quota and missing requests), narrow a quota with scopes, and watch a Deployment stay accepted while its pods are refused.

## Goals

- Create a ResourceQuota from YAML and with `kubectl create quota`, and read it with `kubectl describe quota`.
- Limit compute (`requests.cpu`, `limits.memory` and similar), object counts (`pods`, `count/deployments.apps`) and storage (`requests.storage`, `persistentvolumeclaims`).
- Explain why a pod without requests or limits is rejected when a compute quota exists.
- Limit a subset of pods with a quota scope such as `BestEffort` or `Terminating`.
- Find and fix a workload controller that cannot create pods because of a quota.

## Learning objectives

After this module you can:

- Read `status.used` and `status.hard` and predict whether the next object is admitted.
- Tell an `exceeded quota` rejection from a `must specify` rejection and fix each one.
- Choose between a namespace-wide quota and a scoped quota.
- Locate the `FailedCreate` event that a ReplicaSet or Job records when a quota refuses its pods.
- Change a quota and explain why running pods are not affected.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl create`. You should know that a container can declare a resource request and a resource limit.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. The cluster has no metrics server, so `kubectl top` does not work.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The `scout` (`podinfo`), `probe` (`go-httpbin`) and `shuttle` (`curl`) Deployments, each with one replica and small requests and limits. The Services `scout` and `probe`. No ResourceQuota and no LimitRange |
| `outpost` | The `drifter` client Deployment. No ResourceQuota and no LimitRange |

The parts run in this order: compute quota and the two admission errors, object count and storage quotas, quota scopes, and quota with Deployments and Jobs. A summary closes the module.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
