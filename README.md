# Application Environment, Configuration and Security (ATS029)

Certified Kubernetes Application Developer (CKAD): Application Environment, Configuration and Security, worth 25% of the curriculum and part of ATP006.

Each section has an introduction. Each module combines detailed concept readings, an ungraded isolated playground, guided practical work and a closing summary. YAML knowledge checks remain separately indexed. Technical content stays draft for review. Every active module includes a draft independent graded lab.

## Course Outline

Each of the eight sections (one per official competency) has three modules (each with a playground and a graded lab), an integrated capstone lab and a section quiz. The course ends with a final domain quiz.

| Section | Modules | Capstone |
| --- | --- | --- |
| 010 Custom resources and operators | Custom types; Define a CustomResourceDefinition; Discover and operate with operators | Repair a Hangar API and its operator |
| 020 Authentication, authorization, admission | Identity and API access; Authentication and client certificates; Admission control | Certificate user, RBAC and an admission policy |
| 030 Requests, limits, quotas | Allocation and namespace policy; ResourceQuota in depth; LimitRange, QoS and runtime | Quota and defaults for a namespace |
| 040 ConfigMaps | Configuration delivery; Creating ConfigMaps; Consuming ConfigMaps | Versioned immutable ConfigMaps and rollout |
| 050 Resource requirements | Container requirements; Requests, limits and QoS; Namespace policy, storage and right-sizing | Right-size workloads under a quota |
| 060 Secrets | Secret consumption; Creating Secrets; Consuming Secrets | Rotate and consume Secrets with least privilege |
| 070 ServiceAccounts | Workload identity; Create and assign ServiceAccounts; Tokens and API access | Remove broad grants, assign narrow identities |
| 080 Application security | Security contexts; Users, groups and capabilities; Seccomp, host access and Pod Security | Harden a Deployment without lowering the namespace level |

## Author Review

See [curriculum coverage](CURRICULUM.md), [primary sources](SOURCES.md), [assessment contracts](ASSESSMENTS.md) and [contribution guidance](CONTRIBUTING.md). Every section has a `quiz.yaml` knowledge check, and `sections/final-domain-quiz.yaml` closes the manifest. All labs and playgrounds are UNTESTED: authored with static checks only (`astrona validate -c`, `bash -n`, YAML parsing). Live execution remains pending; do not claim runtime results.
