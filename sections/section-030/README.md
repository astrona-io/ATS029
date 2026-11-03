---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Understand requests, limits, quotas

This section covers understand requests, limits, quotas. You will study Allocation, Enforcement And Namespace Policy. The lessons explain the responsible components, configuration relationships and failure cases relevant to application development.

Each module begins with its goals and ends with a summary. Reusable YAML knowledge checks follow the section summary and are registered separately for future presentation.


You will interpret resource policy at admission, capacity at scheduling and usage boundaries during execution. Read defaults in the admitted object before calculating requirements. A namespace allowance does not reserve a node or remove a runtime memory limit.

## Learning Outcomes

- Distinguish resource requests from usage and limits.
- Explain CPU and memory enforcement differences.
- Identify defaults and quota admission effects.
- Diagnose allocation policy separately from placement.
- Write ResourceQuota objects for compute, object counts and storage, and limit them with scopes.
- Read the two quota admission errors and find quota refusals recorded on a ReplicaSet.
- Write a LimitRange with defaults, minimum, maximum and a limit to request ratio.
- Predict the QoS class of a Pod and diagnose CPU throttling, OOMKilled containers, Pending Pods and eviction order.

## Modules

- Module 01 introduces requests, limits and a namespace Pod budget.
- Module 02 covers ResourceQuota in depth: compute quotas and admission errors, object count and storage quotas, scopes, and quotas with Deployments.
- Module 03 covers LimitRange, QoS classes and runtime behaviour: CPU throttling, OOMKilled containers, Pending Pods and eviction.
- The capstone lab combines a LimitRange, a ResourceQuota and a QoS fix in one namespace.

Each module pairs its concept readings with a guided practical sequence in an isolated playground. Finish the practice and closing summary before moving on. The YAML knowledge checks remain separate from the environment lifecycle.
