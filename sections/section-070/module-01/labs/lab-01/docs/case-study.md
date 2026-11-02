---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Create ServiceAccount `observer`, Role `observer-reader` granting exactly get and list on core Pods, and RoleBinding `observer-read` for that identity in `starfleet`. Run both probe replicas as that ServiceAccount. A request from the application container using its mounted token and certificate authority must read the namespace Pod list. Secret reads and Pod creation must remain denied.
