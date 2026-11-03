---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Define A CustomResourceDefinition

Kubernetes knows a fixed list of resource types, such as Pods, Deployments and Services. A CustomResourceDefinition (CRD) adds a new type to that list without changing Kubernetes itself. After the API server accepts the CRD, you create, read, change and delete objects of the new type with the same `kubectl` commands you use for built-in types. This module teaches you to write that definition, to make the API server reject bad objects, and to change the definition over time.

Keep one sentence in mind for the module: **a CRD is the contract of a new API type, and the API server enforces it on every request.** The CRD names the type, says whether its objects live in a namespace, lists its versions, and carries the schema that every object must follow. A CRD adds no behaviour. Nothing in this module runs a controller.

The module has three parts. The first part writes a small CRD, waits until the API server serves it, and creates the first custom resource. The second part reads a complete CRD with validation rules, defaults, printer columns and a status subresource, and breaks each rule on purpose. The third part adds a second version to a CRD, shows what the API server stores, and shows what happens to the objects when the CRD is deleted.

## Learning objectives

After this module you can:

- Write a CRD with the correct name, group, names, scope, version and schema, and apply it.
- Wait for the `Established` condition and find the new type with `kubectl api-resources` and `kubectl explain`.
- Create, list, patch and delete custom resources, with the full name and with a short name.
- Write schema rules (`required`, `enum`, `minimum`, `default`) and a validation rule in the Common Expression Language (CEL), and read the errors they produce.
- Add printer columns and a status subresource, and explain how a patch of the status differs from a patch of the spec.
- Serve two versions of one CRD, and explain `served`, `storage` and `storedVersions`.
- Explain what happens to custom resources when their CRD is deleted.

## Before you start

You need Kubernetes basics: namespaces, `kubectl get`, `kubectl apply`, `kubectl describe`, and reading YAML. You do not need to know how to program a controller.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Object | What it is |
| --- | --- |
| `starfleet` and `outpost` | Two empty namespaces for your custom resources |
| `telemetries.fleet.astrona.io` | A complete reference CRD for the kind `Telemetry`, with validation, defaults, printer columns and a status subresource. No `Telemetry` exists yet |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
