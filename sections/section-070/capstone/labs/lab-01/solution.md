# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run end to end yet, so the output is described in words.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/capstone/labs/lab-01
```

## Step 1: Remove the administrator access from default

Find the binding that names the account:

```sh
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(any(.subjects[]?; .kind == "ServiceAccount" and .name == "default" and .namespace == "starfleet")) | .metadata.name'
```

The command prints `starfleet-default-admin`. Delete it, then ask the authorizer:

```sh
kubectl delete clusterrolebinding starfleet-default-admin
kubectl auth can-i list secrets --all-namespaces --as=system:serviceaccount:starfleet:default
```

The answer is `no`. Keep the `default` ServiceAccount itself, because pods that name no account still need it. The check `default-account-unprivileged` passes.

## Step 2: Give bridge its own account and one permission

Save this as `serviceaccount-bridge.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bridge
  namespace: starfleet
imagePullSecrets:
  - name: regcred
```

Apply it, then create the Role and the RoleBinding:

```sh
kubectl apply -f serviceaccount-bridge.yaml
kubectl -n starfleet create role pod-reader --verb=get,list,watch --resource=pods
kubectl -n starfleet create rolebinding bridge-pod-reader --role=pod-reader --serviceaccount=starfleet:bridge
```

Point the Deployment at the account. The admission controller copies the account's pull secrets into each new pod, so apply the account first:

```sh
kubectl -n starfleet set serviceaccount deployment bridge bridge
kubectl -n starfleet rollout status deployment bridge
```

Check the pod and the permission:

```sh
kubectl -n starfleet get pods -l app=bridge -o jsonpath='{.items[0].spec.imagePullSecrets}{"\n"}'
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:bridge
kubectl auth can-i list secrets -n starfleet --as=system:serviceaccount:starfleet:bridge
```

The first command shows `regcred`, and the answers are `yes` and `no`. Send the real request from the pod:

```sh
kubectl -n starfleet exec deploy/bridge -- sh -c 'curl -s -o /dev/null -w "%{http_code}\n" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/starfleet/pods'
```

It prints `200`. Change `pods` to `secrets` at the end of the address and it prints `403`.

## Step 3: Take the token away from scout

The setting belongs on the account. Save this as `serviceaccount-scout.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scout
  namespace: starfleet
automountServiceAccountToken: false
```

Apply it and roll the Deployment:

```sh
kubectl apply -f serviceaccount-scout.yaml
kubectl -n starfleet set serviceaccount deployment scout scout
kubectl -n starfleet rollout status deployment scout
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].spec.volumes[*].name}{"\n"}'
```

The last command prints an empty line, because the pod has no volumes. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/capstone/labs/lab-01
```

All six checks must pass. Then remove the lab:

```sh
astrona destroy ats-029-capstone-070
```
