---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Summary

Authentication establishes identity, authorization evaluates allowed actions and admission can validate or alter accepted operations. These stages answer different questions about a request.

Role scope and bindings determine effective API authority under their applicable rules. Workload identity does not automatically grant broad permissions, and an admission policy does not replace the need for deliberate access grants.

Identity, additive permission grants and admission policy form separate request decisions. A narrow grant matches the application's real operations, while its binding type and namespace determine where those operations are allowed.

<!-- astrona:playground:destroy -->
