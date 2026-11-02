---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Create ProbeSetting `greeting` in `starfleet` using `training.astrona.io/v1`, with `spec.message: configured`. The supplied controller must mark it ready and produce ConfigMap `settings-greeting` with `data.message: configured`. Keep the controller running. Do not manually create the output ConfigMap instead of the custom resource.
