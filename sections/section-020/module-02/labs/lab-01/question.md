# Question

Solve this question on: `terminal`

A new developer, `ensign-lee`, joins the team that runs the `drifter` Deployment in the `outpost` namespace. The cluster has no account for the developer yet. `kubectl` already points at the cluster as the cluster administrator. You need `openssl` on your own machine.

1. Create a private key and a certificate signing request for the user `ensign-lee`. Submit it to the cluster as a CertificateSigningRequest object named `ensign-lee` with the signer `kubernetes.io/kube-apiserver-client`, the usage `client auth`, and a lifetime of one day. Approve it, so the cluster issues a client certificate.

2. Add the user to your kubeconfig. Create the credentials `ensign-lee` from the key and the issued certificate, with the certificate data embedded in the kubeconfig, and a context named `ensign-lee` that uses the same cluster as your current context and the namespace `outpost`. Running `kubectl --context ensign-lee auth whoami` must report the user `ensign-lee`.

3. Give `ensign-lee` read access to the pods in `outpost` and nothing else. Create the Role `pod-viewer` and the RoleBinding `ensign-lee-pod-viewer` in `outpost`, with the verbs `get`, `list` and `watch` on `pods`. Through the `ensign-lee` context, `kubectl get pods` must list the `drifter` pod. The user must not change pods, read Secrets, or read anything in `starfleet`.

Do not use `cluster-admin` and do not create a ClusterRoleBinding. Do not change the cluster administrator's credentials.
