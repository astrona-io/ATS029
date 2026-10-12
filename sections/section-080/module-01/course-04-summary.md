---
draft: true
exam_objectives:
- Understand Application Security (SecurityContexts, Capabilities, etc.)
---
# Summary

Security settings control effective process identity and selected runtime privileges, while admission profiles decide whether workload declarations satisfy a policy. These protections have different scopes and limits.

A useful restricted application still needs compatible image permissions and appropriate writable locations. Reducing privilege does not fix application authorization defects or guarantee isolation from every shared infrastructure risk.

Hardening combines process identity, capabilities, system-call filtering and filesystem restrictions. Admission validates declared settings, while runtime controls enforce accepted behavior. Application compatibility must be designed and checked across both boundaries.

<!-- astrona:playground:destroy -->
