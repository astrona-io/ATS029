---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Summary

Custom definitions add typed API resources, while controllers perform the operational work associated with their instances. Discovery, schema acceptance and reconciliation are separate conditions.

Application-specific status and cleanup require the controller’s documented contract. Permissions, dependencies and finalizers can block progress even when the desired custom object is accepted by the server.

An extension combines a registered API type with executable reconciliation logic. Schema acceptance, observed generation, output objects and controller permissions supply different evidence of whether the requested operation progressed.

<!-- astrona:playground:destroy -->
