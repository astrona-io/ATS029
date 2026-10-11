---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Summary

Custom definitions add typed API resources, while controllers perform the operational work associated with their instances. Discovery, schema acceptance and reconciliation are separate conditions.

Application-specific status and cleanup require the controller’s documented contract. Permissions, dependencies and finalizers can block progress even when the desired custom object is accepted by the server.

<!-- astrona:playground:destroy -->
