---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Create & consume Secrets

This section covers create & consume Secrets. You will study Secret Consumption And Confidentiality Limits. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will separate sensitive-data storage, delivery, adoption and retirement. Verify credential behavior without printing the value. Artifact identity, origin and vulnerability evidence answer additional supply-chain questions and must describe the exact content being deployed.

## Learning Outcomes

- Distinguish Secret representation from encryption.
- Choose mounted or environment-based Secret consumption.
- Explain namespace, workload and registry credential relationships.
- Evaluate who can observe or indirectly obtain confidential data.
- Create Secrets with `kubectl create secret` (generic, tls, docker-registry), from literals, files and environment files, and with `stringData` in YAML.
- Make a Secret immutable and replace it correctly.
- Consume a Secret as environment variables, as a read-only volume with `items` and `defaultMode`, and as an image pull Secret.
- Limit access to one named Secret with a Role and test it with `kubectl auth can-i`.

## Modules

- **Secret Consumption And Confidentiality Limits** covers storage, delivery and rotation, and credentials in image supply chains.
- **Create Secrets With kubectl And YAML** covers the `kubectl create secret` forms, Secret types, `stringData` and immutability.
- **Consume Secrets In Pods** covers environment variables, Secret volumes, projected volumes, image pull Secrets, RBAC on Secrets and encryption at rest.
- The section capstone is one graded lab that creates, rotates, consumes and restricts Secrets, followed by a section knowledge check.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.
