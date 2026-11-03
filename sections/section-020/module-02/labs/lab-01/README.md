---
estimated_duration: 25m
---

# Lab: Create A User With A CertificateSigningRequest

Graded lab for the authentication module. The cluster starts with the namespaces `starfleet` and `outpost` and one Deployment in each. The learner creates a key, a CertificateSigningRequest, a kubeconfig context and a read-only grant for the user `ensign-lee`. The task is in `question.md`; the walkthrough is in `solution.md`. The host needs `openssl` and `kubectl`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-029-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-csr-approved.sh` | The CSR `ensign-lee` uses the client signer, is approved, and the issued certificate has `CN=ensign-lee` |
| `validate-context-whoami.sh` | The context `ensign-lee` exists with embedded key and certificate, the namespace `outpost`, and `auth whoami` returns `ensign-lee` |
| `validate-reads-pods.sh` | Through the new context, `get`, `list` and `watch` on pods in `outpost` are allowed and the `drifter` pod is listed |
| `validate-least-privilege.sh` | The user cannot delete or create pods, read Secrets or Deployments, read `starfleet`, or list all namespaces |
| `validate-no-broad-grant.sh` | No ClusterRoleBinding names the user, the certificate has no `system:masters` group, and the user is authenticated |

All five checks fail in the starting state, because the user does not exist.

UNTESTED: authored statically, not yet run live.
