---
draft: true
exam_objectives:
- Define resource requirements
---
# Summary

Resource declarations must represent the complete workload with correct units and applicable lifecycle accounting. Requests support allocation, while limits and runtime behavior determine separate enforcement outcomes.

Initialization, helpers, defaults and namespace controls can affect the admitted contract. Sizing requires meaningful observation of normal and peak behavior rather than assuming one idle measurement describes every future operation.

Complete resource requirements include the applicable ordinary, init and supporting-container semantics. CPU and memory quantities need correct units, and admitted defaults can change the values that scheduling and runtime actually use.

<!-- astrona:playground:destroy -->
