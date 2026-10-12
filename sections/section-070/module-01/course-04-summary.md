---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Summary

ServiceAccounts provide workload identities, while credential mechanisms make those identities usable for requests. Authorization comes from explicit grants and remains distinct from the existence of an account or mounted token.

Token lifetime, audience and delivery influence credential use. Least privilege requires reviewing the actual resource actions and scope needed by the application, including authority obtained through workload creation or additional bindings.

Workload identity, projected credential delivery and effective permission are separate contracts. Least privilege includes both the API operations granted and whether a process needs credentials at all.

<!-- astrona:playground:destroy -->
