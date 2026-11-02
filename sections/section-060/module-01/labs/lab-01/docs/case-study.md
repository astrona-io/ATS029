---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Starting Environment

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Create Opaque Secret `practice-token` with disposable key `token: disposable-example`. Create Pod `secret-consumer` with required environment variable `PRACTICE_TOKEN` from that Secret key and a read-only Secret volume at `/credentials`. Its process must verify a nonempty environment value matching the mounted file. Do not put credentials in the Pod command or print the value.
