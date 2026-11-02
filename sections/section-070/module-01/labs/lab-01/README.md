---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Use A Workload Identity For An API Request

Run the application with a narrow identity and authenticate a real API request from its container. The task and reference solution use a separate pinned kind cluster. The grader checks declared fields and bounded live evidence. Python 3 is required on the grading host.

Run `testing/smoke.sh` with the lab's private kubeconfig to prove that the starting state fails and the reference repair passes. Each wait and request is bounded. Live verification is pending until actual container-engine execution is recorded. Static checks are not runtime evidence.
