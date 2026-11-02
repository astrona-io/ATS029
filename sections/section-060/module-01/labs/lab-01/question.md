---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Consume A Secret Without Printing It

Use both a required Secret key reference and a read-only Secret volume. Use the isolated `starfleet` environment to verify the result.

## Objective

Use both a required Secret key reference and a read-only Secret volume.

## Starting state

The application and client fixtures are healthy. Complete the required change without replacing unrelated resources.

Use a host shell with this lab's private kubeconfig. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool. This environment is separate from the ungraded playground.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-029-lab-060-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-029-lab-060-01-01" || exit 1
```

Keep this connection selected throughout the task. Every script supplied by the lab refuses a different context.


## Required result

Create Opaque Secret `practice-token` with disposable key `token: disposable-example`. Create Pod `secret-consumer` with required environment variable `PRACTICE_TOKEN` from that Secret key and a read-only Secret volume at `/credentials`. Its process must verify a nonempty environment value matching the mounted file. Do not put credentials in the Pod command or print the value.

## Verify The Result

The grader checks the stated resource fields and live evidence. Wait for controller convergence before submitting. Inspect actual results rather than relying on a sample transcript.
