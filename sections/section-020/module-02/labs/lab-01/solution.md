# Solution

Solve this lab on `terminal`. Each step ends with a check you can run on your own, and with `astrona submit`, which grades the lab. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands below are written from the Kubernetes behaviour; you see slightly different names and times on your machine.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-02/labs/lab-01
```

## Step 1: Create the private key and the request

The subject of the request becomes the identity of the user. `CN` is the user name. Do not add an `O` field, because `O` would add groups.

```sh
openssl genrsa -out ensign-lee.key 2048
openssl req -new -key ensign-lee.key -subj "/CN=ensign-lee" -out ensign-lee.csr
base64 < ensign-lee.csr | tr -d '\n'
```

The last command prints the request as one line of base64 text. Copy it for the next step.

## Step 2: Submit and approve the CertificateSigningRequest

Save this as `csr-ensign-lee.yaml`, and replace `<REQUEST>` with the base64 line from step 1:

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ensign-lee
spec:
  request: <REQUEST>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
```

Apply it and approve it:

```sh
kubectl apply -f csr-ensign-lee.yaml
kubectl certificate approve ensign-lee
```

Then check the result. The `CONDITION` column must show `Approved,Issued`:

```sh
kubectl get csr ensign-lee
```

If the condition shows only `Approved`, wait a few seconds and run it again. The controller manager signs the request after the approval. Run `astrona submit --keep`: the check `csr-approved-and-issued` passes.

## Step 3: Save the certificate and add the user to the kubeconfig

```sh
kubectl get csr ensign-lee -o jsonpath='{.status.certificate}' | base64 -d > ensign-lee.crt
CLUSTER="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
kubectl config set-credentials ensign-lee --client-key=ensign-lee.key --client-certificate=ensign-lee.crt --embed-certs=true
kubectl config set-context ensign-lee --cluster="$CLUSTER" --user=ensign-lee --namespace=outpost
```

Check that the API server accepts the certificate:

```sh
kubectl --context ensign-lee auth whoami
```

The table must show the username `ensign-lee`. Run `astrona submit --keep`: the check `kubeconfig-context-works` passes. The three checks about access still fail, because the user has no Role yet.

## Step 4: Grant read access to pods in outpost

```sh
kubectl -n outpost create role pod-viewer --verb=get,list,watch --resource=pods
kubectl -n outpost create rolebinding ensign-lee-pod-viewer --role=pod-viewer --user=ensign-lee
```

Check the answers through the new context:

```sh
kubectl --context ensign-lee -n outpost auth can-i list pods
kubectl --context ensign-lee -n outpost auth can-i delete pods
kubectl --context ensign-lee -n starfleet auth can-i list pods
kubectl --context ensign-lee get pods
```

The three `can-i` commands print `yes`, `no` and `no`. The last command lists the `drifter` pod, because the context uses the namespace `outpost`. Run `astrona submit`: all five checks pass.

## Why this works

The cluster certificate authority signs the approved request, so the API server trusts the certificate and reads `CN=ensign-lee` as the user name. Authentication stops there. The Role and the RoleBinding in `outpost` are the only grants, so every request outside that namespace or with another verb is denied by authorization.
