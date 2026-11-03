---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Understand Application Security (SecurityContexts, Capabilities, etc.)

This section covers understand Application Security (SecurityContexts, Capabilities, etc.). You will study three modules: Security Contexts And Application Privilege, Users, Groups, Capabilities And Privilege, and Seccomp, Host Access And Pod Security Admission. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will combine execution restrictions with the actual files and operations an application requires. Admission profiles check declared settings, while runtime controls act on accepted processes. A protection should be explained through its effect, scope and remaining limits.

## Learning Outcomes

- Distinguish Pod and container security settings.
- Explain non-root identity, privilege and capabilities.
- Evaluate filesystem access and writable paths.
- Distinguish admission profile checks from runtime isolation.
- Set runAsUser, runAsGroup, fsGroup and supplementalGroups, and predict which Pod-level or container-level value applies.
- Add and drop Linux capabilities, and explain allowPrivilegeEscalation and privileged containers.
- Set a seccomp profile, a read-only root filesystem with writable volumes, and safe sysctls.
- Explain what hostNetwork, hostPID, hostIPC and hostPath give a Pod and which Pod Security level rejects them.
- Find the rejection of a Deployment in a restricted namespace and fix its Pod template.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.

## Modules

1. Security Contexts And Application Privilege: Pod and container security settings, profile requirements and a read-only root filesystem.
2. Users, Groups, Capabilities And Privilege: numeric identity, volume ownership with fsGroup, capabilities, allowPrivilegeEscalation and privileged containers.
3. Seccomp, Host Access And Pod Security Admission: seccomp profiles, host access, sysctls and a Deployment rejected by a namespace policy.

The section ends with a capstone lab that combines all three modules and a knowledge check.
