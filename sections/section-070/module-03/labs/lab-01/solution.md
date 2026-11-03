# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run end to end yet, so the output is described in words.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-03/labs/lab-01
```

## Step 1: Reproduce the failure

Send the request from inside the `shuttle` pod, with the mounted token and certificate authority file:

```sh
kubectl -n starfleet exec deploy/shuttle -- sh -c 'curl -s -w "\nHTTP %{http_code}\n" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/starfleet/pods'
```

The response ends with `HTTP 403`. The message says that the user `system:serviceaccount:starfleet:default` cannot list the resource `pods` in the namespace `starfleet`. The token works, because a bad token would return `401`. The account has no permission.

## Step 2: Create the account and point the Deployment at it

```sh
kubectl -n starfleet create serviceaccount shuttle
kubectl -n starfleet set serviceaccount deployment shuttle shuttle
kubectl -n starfleet rollout status deployment shuttle
```

The new `shuttle` pod runs as the `shuttle` account. Its request still returns `403`, because the account has no Role yet. The check `shuttle-uses-own-account` passes now.

## Step 3: Create the Role and the RoleBinding

The Role lists the three read verbs on pods only. The binding subject needs the namespace:

```sh
kubectl -n starfleet create role pod-reader --verb=get,list,watch --resource=pods
kubectl -n starfleet create rolebinding shuttle-pod-reader --role=pod-reader --serviceaccount=starfleet:shuttle
```

Test the permission from your own terminal before you test the pod:

```sh
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:shuttle
kubectl auth can-i list secrets -n starfleet --as=system:serviceaccount:starfleet:shuttle
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:shuttle
```

The answers are `yes`, `no` and `no`. Do not use `--clusterrole=view` or a ClusterRoleBinding: `view` also reads other resources, and a ClusterRoleBinding reaches every namespace.

## Step 4: Repeat the request

Run the same `curl` command as in step 1. The response is the list of pods in JSON and ends with `HTTP 200`. Change the path to `/api/v1/namespaces/starfleet/secrets` and run it again. It ends with `HTTP 403`, now naming the user `system:serviceaccount:starfleet:shuttle`.

Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-03/labs/lab-01
```

All five checks must pass. If `shuttle-lists-pods` fails with a `403` after the Role exists, check the subject of the binding with `kubectl -n starfleet get rolebinding shuttle-pod-reader -o yaml`: the name and the namespace must be `shuttle` and `starfleet`. Then remove the lab:

```sh
astrona destroy ats-029-lab-070-03
```
