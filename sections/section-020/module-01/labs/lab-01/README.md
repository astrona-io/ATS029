---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Grant Namespace Pod Read Access

Grant a ServiceAccount only Pod read access in the required namespace and verify denied operations. This independent graded environment is separate from the module playground.

Author checks: run `astrona validate -c ATS029/sections/section-020/module-01/labs/lab-01` from the workspace. In a fresh lab, run `testing/smoke.sh` with its private kubeconfig to confirm that the initial state fails, the reference solution passes and convergence completes. The grader requires Python 3 on the host.

Runtime verification is pending. Static checks and offline grader tests do not prove cluster execution.
