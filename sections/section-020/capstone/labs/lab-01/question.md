# Question

Solve this question on: `terminal`

The bridge crew takes over the `drifter` workload in the `outpost` namespace. A new developer, `ensign-park`, belongs to the crew, and every crew member will get a certificate with the group `bridge-crew`. The cluster has no account for the developer and no rule about container images. `kubectl` already points at the cluster as the cluster administrator. You need `openssl` on your own machine.

1. Create a private key and a certificate signing request with the subject `CN=ensign-park` and the organization `bridge-crew`. Submit it as the CertificateSigningRequest `ensign-park` with the signer `kubernetes.io/kube-apiserver-client`, the usage `client auth` and a lifetime of one day, and approve it. Add the user to your kubeconfig with the certificate data embedded, and create the context `ensign-park` for the same cluster with the namespace `outpost`. `kubectl --context ensign-park auth whoami` must report the user `ensign-park`.

2. Give the group `bridge-crew` (not the single user) the rights to `get`, `list`, `watch`, `create`, `update` and `patch` Deployments, and to `get`, `list` and `watch` pods, in `outpost` only. Use a Role named `crew-deployer` and a RoleBinding named `bridge-crew-deployer`. The group must not delete Deployments, create pods, read Secrets or reach `starfleet`. Do not use `cluster-admin`, `admin` or `edit`, and do not create a ClusterRoleBinding.

3. Create the ValidatingAdmissionPolicy `pinned-images` and the ValidatingAdmissionPolicyBinding `pinned-images-outpost`. In `outpost`, the policy must reject a Deployment whose container image has no tag or the tag `latest`, on create and on update. The binding must reject requests with the action `Deny` and must apply only to `outpost`. A Deployment with the image `busybox:1.37.0` must be accepted, also through the `ensign-park` context.

Do not delete or change the `drifter` and `scout` Deployments.
