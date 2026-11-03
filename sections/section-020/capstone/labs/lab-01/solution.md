# Solution

Solve this lab on `terminal`. Each step ends with a check you can run on your own, and with `astrona submit`, which grades the lab. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands below are written from the Kubernetes behaviour; you see slightly different names and times on your machine.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/capstone/labs/lab-01
```

## Step 1: Create the certificate and the context

The subject of the request becomes the identity: `CN` is the user name and each `O` is a group. Create the key and the request, and print the request as one base64 line:

```sh
openssl genrsa -out ensign-park.key 2048
openssl req -new -key ensign-park.key -subj "/CN=ensign-park/O=bridge-crew" -out ensign-park.csr
base64 < ensign-park.csr | tr -d '\n'
```

Save this as `csr-ensign-park.yaml`, and replace `<REQUEST>` with the base64 line:

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ensign-park
spec:
  request: <REQUEST>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
```

Apply it and approve it:

```sh
kubectl apply -f csr-ensign-park.yaml
kubectl certificate approve ensign-park
```

Then check the result. The `CONDITION` column must show `Approved,Issued`. If it shows only `Approved`, wait a few seconds and run it again:

```sh
kubectl get csr ensign-park
```

Save the certificate, add the user and create the context:

```sh
kubectl get csr ensign-park -o jsonpath='{.status.certificate}' | base64 -d > ensign-park.crt
CLUSTER="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
kubectl config set-credentials ensign-park --client-key=ensign-park.key --client-certificate=ensign-park.crt --embed-certs=true
kubectl config set-context ensign-park --cluster="$CLUSTER" --user=ensign-park --namespace=outpost
kubectl --context ensign-park auth whoami
```

The table shows the username `ensign-park` and the group `bridge-crew`. Run `astrona submit --keep`: the check `identity-from-certificate` passes.

## Step 2: Grant the group its rights in outpost

The grant goes to the group, so every future crew certificate with `O=bridge-crew` works without a new binding. Save this as `role-crew-deployer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: crew-deployer
  namespace: outpost
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

Save this as `rolebinding-bridge-crew-deployer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bridge-crew-deployer
  namespace: outpost
subjects:
  - kind: Group
    name: bridge-crew
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: crew-deployer
  apiGroup: rbac.authorization.k8s.io
```

Apply both files:

```sh
kubectl apply -f role-crew-deployer.yaml
kubectl apply -f rolebinding-bridge-crew-deployer.yaml
```

Then check the answers. The first prints `yes`. The next three print `no`:

```sh
kubectl --context ensign-park auth can-i create deployments.apps
kubectl --context ensign-park auth can-i delete deployments.apps
kubectl --context ensign-park auth can-i get secrets
kubectl --context ensign-park auth can-i list pods --namespace starfleet
```

Run `astrona submit --keep`: the checks `group-manages-deployments` and `least-privilege` pass.

## Step 3: Reject unpinned images with a policy

Save this as `validatingadmissionpolicy-pinned-images.yaml`. The expression reads every container of the pod template. It requires a colon in the image name and rejects the tag `latest`. An image with no tag has no colon, and Kubernetes pulls `latest` for it:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: pinned-images
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.template.spec.containers.all(c, c.image.contains(':') && !c.image.endsWith(':latest'))"
      message: "Container images must use an explicit tag other than latest."
```

Save this as `validatingadmissionpolicybinding-pinned-images-outpost.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: pinned-images-outpost
spec:
  policyName: pinned-images
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: outpost
```

Apply both files:

```sh
kubectl apply -f validatingadmissionpolicy-pinned-images.yaml
kubectl apply -f validatingadmissionpolicybinding-pinned-images-outpost.yaml
```

Wait a few seconds, then test as the new user with a server-side dry run:

```sh
kubectl --context ensign-park create deployment bridge --image=busybox:latest --dry-run=server
kubectl --context ensign-park create deployment bridge --image=busybox:1.37.0 --dry-run=server
```

The first command fails. Its message names the policy `pinned-images` and not a missing permission, which shows that authorization allowed the request and admission refused the object. The second command succeeds. Run `astrona submit`: all five checks pass.

## Why this works

The certificate authority signs the subject, so the API server authenticates the user as `ensign-park` in the group `bridge-crew`. Authorization then grants rights through the RoleBinding to that group, only in `outpost`, and only for the listed verbs. Admission runs last and judges the Deployment itself, so the user is allowed to create Deployments and the policy still rejects the ones with an unpinned image.
