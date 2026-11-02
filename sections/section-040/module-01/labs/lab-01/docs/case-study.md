---
draft: true
exam_objectives:
- Understand ConfigMaps
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Create ConfigMap `probe-settings` with `greeting: mounted`. Mount it as read-only volume `settings` at `/settings` in container `probe`. Keep two healthy replicas and the existing application code. The original client must receive `greeting=mounted` from the application, which reads the mounted file for each request.
