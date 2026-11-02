# Application Environment, Configuration and Security (ATS029)

Certified Kubernetes Application Developer (CKAD): Application Environment, Configuration and Security, worth 25% of the curriculum and part of ATP006.

Each section has an introduction. Each module combines detailed concept readings, an ungraded isolated playground, guided practical work and a closing summary. YAML knowledge checks remain separately indexed. Technical content stays draft for review. New graded labs are not included.

## Course Outline

| Section / module | Module | Concept and practical readings |
| --- | --- | --- |
| 010 / 01 | Custom Types And Application Reconciliation | Custom Resources And Operators; Reading A Custom Resource And Its Controller Contract; Create A Custom Resource And Observe Its Controller |
| 020 / 01 | Identity And API Access Decisions | API Request Checks And Workload Identity; RBAC Grants And Their Consequences; Grant One Namespace Permission And Verify A Denial |
| 030 / 01 | Allocation, Enforcement And Namespace Policy | Requests, Limits And Namespace Budgets; Observe Quota Rejection And Resource Accounting |
| 040 / 01 | ConfigMaps And Application Configuration Delivery | ConfigMaps, Secrets And Configuration Delivery; Configuration, Dependencies And Request Failures; Compare Environment And Mounted ConfigMap Updates |
| 050 / 01 | Complete Container Resource Requirements | Expressing Resource Needs For Every Container; Declare Resources For Every Ordinary Container |
| 060 / 01 | Secret Consumption And Confidentiality Limits | Secret Storage, Delivery And Rotation; Credentials And Image Supply Chains; Consume A Disposable Secret Without Printing Its Value |
| 070 / 01 | ServiceAccounts And Bound Workload Credentials | API Identity And ServiceAccounts; RBAC Scope And Least Privilege; Use A Workload ServiceAccount For A Real API Request |
| 080 / 01 | Security Contexts And Application Privilege | Security Contexts And Profile Requirements; Security Contexts And Pod Admission; Run Non-Root With A Read-Only Root Filesystem |

## Author Review

See [curriculum coverage](CURRICULUM.md), [primary sources](SOURCES.md), [assessment contracts](ASSESSMENTS.md) and [contribution guidance](CONTRIBUTING.md). Each playground has its own config, bootstrap, guide and author smoke script. Static checks passed; live execution remains pending because the authoring session cannot access the container engine. Retain that limitation until real runtime evidence is recorded.
