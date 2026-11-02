---
draft: true
exam_objectives:
- Define resource requirements
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Keep two probe replicas and add ordinary container `observer` using BusyBox 1.37.0 with a sleeping process. Declare probe requests of 20m CPU and 32Mi memory with limits of 100m and 128Mi. Declare observer requests of 10m and 16Mi with limits of 50m and 64Mi. Both containers must be ready in both Pods. Preserve the original Service response.
