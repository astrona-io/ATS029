---
estimated_duration: 40m
---

# Capstone: Authentication, Authorization And Admission

Integrated graded lab for the section. The cluster starts with the namespaces `starfleet` and `outpost` and one busybox Deployment in each. The learner issues a client certificate with a group through a CertificateSigningRequest, builds a kubeconfig context, grants the group narrow rights in one namespace, and rejects unpinned images with a `ValidatingAdmissionPolicy`. The task is in `question.md`; the walkthrough is in `solution.md`. The host needs `openssl` and `kubectl`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-029-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-identity.sh` | The CSR is approved and issued with `CN=ensign-park` and `O=bridge-crew`; the context embeds the credentials, uses `outpost`, and `auth whoami` shows the user and the group |
| `validate-group-grant.sh` | Another user name in the group `bridge-crew` gets the Deployment and pod rights, so the grant is on the group, not on one user |
| `validate-least-privilege.sh` | The group cannot delete Deployments, create pods, read Secrets or Services, or reach `starfleet` |
| `validate-image-policy.sh` | Through the user's context, `busybox:latest` and an untagged image are rejected by a ValidatingAdmissionPolicy, `busybox:1.37.0` is accepted, an update of `drifter` is rejected, and `starfleet` is not affected |
| `validate-no-broad-grant.sh` | No ClusterRoleBinding and no `edit`, `admin` or `cluster-admin` RoleBinding names the user or the group, and the certificate has no `system:masters` |

All checks fail in the starting state, because the user does not exist. The policy checks retry for about 30 seconds.

UNTESTED: authored statically, not yet run live.
