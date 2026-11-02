---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Summary

Secrets connect confidential values to workloads under API, storage and runtime controls. Encoding is not encryption, and choosing the Secret resource kind does not remove all exposure paths.

Application delivery and registry authentication serve different purposes. Access review must include identities that can read resources, create consuming workloads or inspect execution, alongside appropriate key rotation and application reload behavior.

Secret handling needs access control, protected storage and careful consumer behavior beyond base64 encoding. Rotation is complete only through planned adoption and retirement, verified without exposing credential contents.

<!-- astrona:playground:destroy -->
