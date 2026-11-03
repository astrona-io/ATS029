---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Summary

A CustomResourceDefinition (CRD) registers a new resource type with the API server. After the CRD is established, the type works with the same `kubectl` commands as a built-in type, and the API server validates and stores its objects. The CRD adds no behaviour of its own.

## What you learned

A CRD has the name `<plural>.<group>`. Its `spec` sets the group, the names (kind, plural, singular, short names), the scope and a list of versions. The scope is `Namespaced` or `Cluster`, and the group, the scope and the kind cannot change after creation. Each version has a structural OpenAPI v3 schema. The `Established` condition tells you when the API server serves the type, and `kubectl api-resources` and `kubectl explain` show the result: the kind, the short name, the scope and the fields.

The schema is the contract that the API server enforces on every request. `required`, `enum`, `minimum`, `maximum` and `default` shape the object. The API server applies defaults first and validates second. A field that the schema does not declare is rejected by strict validation or pruned when strict validation is off. A Common Expression Language (CEL) rule in `x-kubernetes-validations` checks a condition across fields and returns the message of the rule when it fails. Printer columns change only what `kubectl get` prints.

The status subresource separates the desired state from the observed state. With it enabled, a patch of the whole object ignores `status`, and only the `/status` endpoint changes it. A change of `spec` raises `metadata.generation`, and a change of `status` does not.

A CRD can serve several versions. Exactly one version is the storage version. The `None` conversion strategy changes only the `apiVersion`, so it fits versions with the same fields. The field `status.storedVersions` lists every version that may have objects in etcd, and a version leaves the CRD only after every object is rewritten. Deleting a CRD deletes every object of the type, in all namespaces, and a finalizer on one object can hold the deletion.

Key facts to remember:

- Wait for the `Established` condition of a CRD before you create the first object.
- Namespaced custom resources need a namespace or the all-namespaces option.
- Write status through the status endpoint, not through the main object.
- A CRD stores and validates data. A controller, which a CRD does not include, acts on it.

<!-- astrona:playground:destroy -->
