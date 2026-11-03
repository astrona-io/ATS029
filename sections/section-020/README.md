---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Understand authentication, authorization and admission control

This section covers understand authentication, authorization and admission control. You will study three modules: Identity And API Access Decisions, Authentication, Client Certificates And kubeconfig, and Admission Control. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will trace request acceptance through identity, permission and admission. Read all applicable bindings and their namespace scope when evaluating effective authority. A valid credential or an allowed verb does not establish that every proposed configuration will be accepted.

## Learning Outcomes

- Distinguish authentication, authorization and admission.
- Explain workload identity in API requests.
- Evaluate role scope and additive grants.
- Diagnose denial at the correct access-control stage.
- Issue a client certificate through a CertificateSigningRequest and build a kubeconfig context for it.
- Check access with `kubectl auth whoami`, `kubectl auth can-i` and impersonation.
- Explain mutating and validating admission and the built-in plugins LimitRanger, ResourceQuota and NamespaceLifecycle.
- Write a ValidatingAdmissionPolicy and a binding, and preview decisions with `--dry-run=server`.

## Modules

1. Identity And API Access Decisions: request checks, workload identity and RBAC grants.
2. Authentication, Client Certificates And kubeconfig: credentials, CertificateSigningRequest, contexts and access checks.
3. Admission Control: mutation, defaults, quotas and ValidatingAdmissionPolicy.

A capstone lab joins the three layers, and a knowledge check closes the section.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.
