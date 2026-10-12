---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Understand ServiceAccounts

This section covers understand ServiceAccounts. You will study ServiceAccounts And Bound Workload Credentials. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will read workload identity separately from credential delivery and role grants. A namespace-qualified ServiceAccount and a narrow binding define different parts of API access. Processes that do not need that access should not receive unnecessary authority or credentials.

## Learning Outcomes

- Explain ServiceAccount identity and namespace scope.
- Distinguish credential delivery from permission grants.
- Evaluate token audience, expiry and workload use.
- Choose least-privilege access for an application role.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.
