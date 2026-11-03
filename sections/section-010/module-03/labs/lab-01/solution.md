# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-03/labs/lab-01
```

## Step 1: Find out why scout-bay does not reconcile

An operator reports its problems in three places: the status of the custom resource, the log of the operator, and the permissions of its service account. Start with the custom resource:

```sh
kubectl -n starfleet get hangar scout-bay -o yaml
```

The condition `Ready` is not `True`, and its `reason` and `message` fields name the failing step. The reason is `DeploymentFailed`, and the message holds an HTTP status code. Read the operator log to see the full error:

```sh
kubectl -n fleet-system logs deployment/hangar-operator
```

The log shows that the operator was refused when it tried to create the Deployment `hangar-scout-bay`. Code `403` means the API server rejected the request because of authorization. Confirm it by asking the API server what the service account may do:

```sh
kubectl auth can-i create deployments.apps -n starfleet --as=system:serviceaccount:fleet-system:hangar-operator
kubectl auth can-i patch deployments.apps -n starfleet --as=system:serviceaccount:fleet-system:hangar-operator
```

The first command prints `no` and the second prints `yes`. The operator may change existing Deployments but may not create new ones.

## Step 2: Add only the missing verb

Look at the rules of the `ClusterRole`:

```sh
kubectl get clusterrole hangar-operator -o yaml
```

The rule for the resource `deployments` in the group `apps` lists the verbs `get`, `list`, `watch` and `patch`. The verb `create` is missing. The rule is the third entry, which has the index 2. Add the one verb with a JSON patch:

```sh
kubectl patch clusterrole hangar-operator --type=json \
  -p '[{"op":"replace","path":"/rules/2/verbs","value":["get","list","watch","create","patch"]}]'
```

Then check:

```sh
kubectl auth can-i create deployments.apps -n starfleet --as=system:serviceaccount:fleet-system:hangar-operator
```

The command prints `yes`. Do not bind the service account to `cluster-admin`, `admin` or `edit`, and do not use a wildcard. Those fix the symptom but give the operator rights it does not need, and the grader rejects them.

Run `astrona submit --keep`. The check for the operator permission passes. The check for `scout-bay` may still fail for a few seconds, because the operator retries every three seconds.

## Step 3: Wait for scout-bay to become ready

The operator retries on its own. Do not delete `scout-bay` and do not create the Deployment by hand. A Deployment that the operator did not create has no owner reference, and a recreated `scout-bay` has a new uid. The grader rejects both.

```sh
kubectl -n starfleet wait --for=condition=Ready hangar/scout-bay --timeout=240s
```

Then check the result and the owner reference:

```sh
kubectl -n starfleet get hangar scout-bay
kubectl -n starfleet get deployment hangar-scout-bay -o jsonpath='{.metadata.ownerReferences[0].kind}{"\n"}'
```

The second command prints `Hangar`. The Deployment has two available replicas, and the status of `scout-bay` describes the current generation.

## Step 4: Remove old-bay

Look at the object:

```sh
kubectl -n starfleet get hangar old-bay -o jsonpath='{.metadata.deletionTimestamp}{"\n"}{.metadata.finalizers}{"\n"}'
```

The deletion timestamp is set, so the delete request was accepted. The object stays because it carries the finalizer `legacy.astrona.io/archive`. A finalizer blocks removal until the controller that owns it removes the entry. The operator `hangar-operator` does not own this finalizer, and no other controller runs for it, so nothing will ever remove it.

Clear the finalizer by hand:

```sh
kubectl -n starfleet patch hangar old-bay --type=merge -p '{"metadata":{"finalizers":null}}'
```

The API server removes the object as soon as the list is empty. Check:

```sh
kubectl -n starfleet get hangars
```

Only `scout-bay` is listed. Do not delete the CRD. Deleting the CRD deletes every `Hangar` in the cluster.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-03/labs/lab-01
```

All five checks must pass. Then remove the lab:

```sh
astrona destroy ats-029-lab-010-03
```

## Common mistakes

- Binding `cluster-admin`, `admin` or `edit`, or adding a wildcard, passes `scout-bay` but fails the least-privilege check.
- Creating `hangar-scout-bay` by hand fails the owner reference check.
- Deleting and recreating `scout-bay` fails the check on the uid.
- Deleting the CRD fails the check on `old-bay`, because the CRD must stay established.
- A change that only helps `scout-bay` fails the last check, which creates a new `Hangar` and expects the operator to create, scale and clean up its Deployment.
