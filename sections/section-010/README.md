---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Discover and use resources that extend Kubernetes (CRD, Operators)

This section covers discover and use resources that extend Kubernetes (CRD, Operators). You will study Custom Types And Application Reconciliation. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will distinguish registering an API type from implementing its reconciliation. Read scope, schema, desired generation, observed status and output permissions through the actual controller contract. Accepted custom intent does not automatically supply the advanced operations an application might need.

## Learning Outcomes

- Distinguish type registration from controller behavior.
- Read scope, versions and schema of a custom type.
- Interpret desired fields and controller observations.
- Explain prerequisite, permission and finalizer failures.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.
