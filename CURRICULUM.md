# Curriculum Coverage

Exam: Certified Kubernetes Application Developer (CKAD). Domain: Application Environment, Configuration and Security (25%).

The [official objectives](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/) were verified on 2026-10-11. Teaching structure is original; it does not add official exam requirements.

| Section | Official objective | Modules |
| --- | --- | --- |
| 010 | Discover and use resources that extend Kubernetes (CRD, Operators) | 1 |
| 020 | Understand authentication, authorization and admission control | 1 |
| 030 | Understand requests, limits, quotas | 1 |
| 040 | Understand ConfigMaps | 1 |
| 050 | Define resource requirements | 1 |
| 060 | Create & consume Secrets | 1 |
| 070 | Understand ServiceAccounts | 1 |
| 080 | Understand Application Security (SecurityContexts, Capabilities, etc.) | 1 |

| Section / module | Module | Teaching lessons |
| --- | --- | --- |
| 010 / 01 | Custom Types And Application Reconciliation | Custom Resources And Operators; Reading A Custom Resource And Its Controller Contract |
| 020 / 01 | Identity And API Access Decisions | API Request Checks And Workload Identity; RBAC Grants And Their Consequences |
| 030 / 01 | Allocation, Enforcement And Namespace Policy | Requests, Limits And Namespace Budgets |
| 040 / 01 | ConfigMaps And Application Configuration Delivery | ConfigMaps, Secrets And Configuration Delivery; Configuration, Dependencies And Request Failures |
| 050 / 01 | Complete Container Resource Requirements | Expressing Resource Needs For Every Container |
| 060 / 01 | Secret Consumption And Confidentiality Limits | Secret Storage, Delivery And Rotation; Credentials And Image Supply Chains |
| 070 / 01 | ServiceAccounts And Bound Workload Credentials | API Identity And ServiceAccounts; RBAC Scope And Least Privilege |
| 080 / 01 | Security Contexts And Application Privilege | Security Contexts And Profile Requirements; Security Contexts And Pod Admission |

The module goals and adaptation sources are recorded in AUTHORING.yaml. Every official objective is covered. Each section starts with an introduction, and each module ends with a summary. YAML banks follow the relevant summary and remain separate from the Markdown manifest.

This is a reading-only draft. No new labs, playgrounds, command output or runtime verification are included. ATP006 publication remains draft.

## Hands-On Expansion

Playgrounds and guided practical readings were added on 2026-10-12. Every existing module retains its concept readings and gains one practical reading before its renumbered summary. YAML bank placement follows the new summary path. Official weights, objective IDs and ATP006 links are unchanged. Runtime verification is pending; static checks do not establish successful cluster execution.
