---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Create ResourceQuota `practice-budget` in `starfleet` with a hard limit of five Pods. Preserve the two healthy probe replicas and shuttle client. Create ConfigMap `quota-plan` with `capacity: "5"`. Quota status must reflect the five-Pod limit and account for at least the three running fixture Pods. Keep usage within the quota. Inspect the measured headroom before proposing another workload.
