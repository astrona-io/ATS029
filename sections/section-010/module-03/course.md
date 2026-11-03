---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Discover And Operate With Operators

A CustomResourceDefinition (CRD) adds a new type to the Kubernetes API, and an operator is the program that gives the type its behaviour. An application developer meets operators when a platform team installs one and says "create a `Database` object". The developer must then find out what the type means, create an object, read what the operator reports, and fix the object when nothing happens. This module teaches those four tasks with one working operator.

Keep one sentence in mind for the module: **a custom resource states what you want, and an operator, which is a Deployment with its own permissions, reconciles the cluster toward it and reports the result in `status`.** When something fails, the failing component is one of five: the CRD, the object you wrote, the operator workload, the permissions of the operator, or an object that blocks a deletion. The module teaches you to tell them apart with `kubectl`.

The module has four parts. The first part finds the custom types and the operator in a cluster you did not set up. The second part creates a custom resource and reads the result: the objects the operator created and the conditions it wrote. The third part follows ownership: owner references, garbage collection, finalizers and the deletion options. The fourth part troubleshoots a custom resource that does not reconcile, with an operator that is stopped and an operator that lacks a permission.

## Learning objectives

After this module you can:

- Find the custom types, their API groups, scope and versions in a cluster, and read the schema of a type with `kubectl explain`.
- Find the operator that serves a type: its Deployment, its service account and its permissions.
- Create a custom resource and read its `status`, its conditions and the objects the operator created.
- Compare `metadata.generation` with `status.observedGeneration` to see whether the operator has processed the latest change.
- Read owner references and explain how garbage collection deletes dependent objects, and when `--cascade=orphan` keeps them.
- Explain a finalizer, find the reason that an object stays in the `Terminating` state, and remove a stuck finalizer safely.
- Diagnose a custom resource that does not reconcile: a missing CRD, an operator that is not running, a missing permission, and a status that is not written.

## Before you start

You need Kubernetes basics: namespaces, Deployments, service accounts, `kubectl get`, `kubectl describe`, `kubectl logs` and `kubectl patch`. You need to know that a Role lists allowed verbs on resources. You do not need to write a controller.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with one operator installed:

| Object | What it is |
| --- | --- |
| `hangars.fleet.astrona.io` | The CRD of the kind `Hangar`. A `Hangar` states how many replicas of a workload must run |
| `hangar-operator` in `fleet-system` | The operator: a Deployment that runs a controller. It creates a Deployment for each `Hangar` and writes a `Ready` condition |
| `hangar-operator` service account, `ClusterRole` and `ClusterRoleBinding` | The permissions of the operator |
| `starfleet` and `outpost` | Empty namespaces for your `Hangar` objects |

`kubectl` already points at the playground cluster, as the cluster administrator. No `Hangar` exists at the start.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
