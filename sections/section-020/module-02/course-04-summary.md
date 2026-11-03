---
draft: true
exam_objectives:
- Understand authentication, authorization and admission control
---
# Summary

Authentication is the first check on every API request. The API server turns the credential into a username and a list of groups, and it returns `401 Unauthorized` when it cannot. Kubernetes stores no user objects: a name is valid only inside a credential that a trusted authenticator accepted. A client certificate gives the common name as the username and each organization field as a group. A ServiceAccount token gives the username `system:serviceaccount:<namespace>:<name>`. The command `kubectl auth whoami` prints the identity the API server assigned, and the status code tells the stage that failed: `401` for authentication, `403` for authorization.

A new person receives a certificate through a `CertificateSigningRequest`. The person creates the private key and the request with `openssl` and keeps the key. The object names the signer `kubernetes.io/kube-apiserver-client` and the usage `client auth`. An administrator approves it with `kubectl certificate approve`, the controller manager signs it with the cluster certificate authority, and the certificate appears in `status.certificate`. The authority signs the subject exactly as requested, so the approver must read it. Kubernetes cannot revoke a client certificate, so a short lifetime and the removal of the RoleBinding are the controls.

A `kubeconfig` file joins clusters, users and contexts. A context names one cluster, one user and an optional default namespace, and `current-context` picks the one `kubectl` uses. The flag `--embed-certs=true` stores the key and certificate inside the file. Access is checked in three ways: by running the command through the context, by `kubectl auth can-i` with an optional `--list`, and by impersonation with `--as` and `--as-group`, which tests authorization only.

Key facts to remember:

- Authentication runs before authorization and admission.
- `CN` becomes the username and each `O` becomes a group.
- Approve a CertificateSigningRequest only after reading its subject.
- A RoleBinding can name a group that comes from the certificate.
- `kubectl auth can-i` exits with code 1 when the answer is `no`.

<!-- astrona:playground:destroy -->
