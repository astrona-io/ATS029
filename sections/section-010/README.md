---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Discover and use resources that extend Kubernetes (CRD, Operators)

This section covers discovering and using resources that extend Kubernetes. A CustomResourceDefinition adds a new type to the API, and an operator is the controller that gives objects of that type their behavior. The three modules go from reading existing custom resources, to writing the definition of a type, to operating with the operators that serve a type. The lessons explain the responsible components, configuration relationships and failure cases that an application developer meets.

Each module begins with its goals and ends with a summary. The knowledge check in `quiz.yaml` follows the capstone lab and is registered separately from the environment lifecycle.

You will distinguish registering an API type from implementing its reconciliation. You will write a CustomResourceDefinition with scope, versions, a schema with validation and defaults, printer columns and a status subresource, and you will see what happens when it is removed. You will find the custom types and the operator in an unfamiliar cluster, read the status and conditions that an operator reports, follow owner references and finalizers through deletion, and trace a custom resource that does not reconcile to a missing permission.

## Modules

| Module | Topic | Practice |
| --- | --- | --- |
| `module-01` | Custom types and application reconciliation: custom resources, operators and the controller contract | Playground and graded lab |
| `module-02` | Define a CustomResourceDefinition: schema, validation, defaults, printer columns, status subresource, versions and removal | Playground and graded lab |
| `module-03` | Discover and operate with operators: finding types and operators, status and conditions, owner references, finalizers and troubleshooting | Playground and graded lab |
| `capstone` | Repair a CustomResourceDefinition and its operator in one integrated task | Graded lab |

## Learning Outcomes

- Distinguish type registration from controller behavior.
- Read scope, versions and schema of a custom type, and discover custom types with `kubectl get crd` and `kubectl explain`.
- Write a CustomResourceDefinition with a structural schema, validation rules, defaults, printer columns and a status subresource.
- Explain pruning, served and storage versions, and the effect of deleting a CustomResourceDefinition.
- Interpret desired fields, controller observations, conditions and the generation compared with the observed generation.
- Explain owner references, garbage collection, the `--cascade` option and finalizer failures.
- Diagnose a custom resource that does not reconcile from the status, the operator log and the permissions of its service account.

Each module pairs its concept readings with a guided practical sequence in an isolated playground and a graded lab. Finish the practice and the closing summary before moving on. The knowledge check remains separate from the environment lifecycle.
