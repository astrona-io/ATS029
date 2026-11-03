# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/capstone/labs/lab-01
```

## Step 1: Read the state of the API and the operator

Start with what the cluster knows about the type and about the operator:

```sh
kubectl get crd hangars.fleet.astrona.io -o yaml
kubectl -n starfleet get hangars
kubectl -n starfleet get hangar scout-bay -o yaml
kubectl -n fleet-system logs deployment/hangar-operator
```

The CRD has one version, `v1`, and its schema only lists `spec.replicas` and `spec.image`. There is no `subresources` block, no `additionalPrinterColumns` and no `status` in the schema. The listing shows only the names and the age. The operator log shows two kinds of error: a refusal when the operator tries to create the Deployment, and a not-found error when it tries to write the status.

## Step 2: Repair the CRD in place

The not-found error on the status has a cause in the CRD: without the status subresource there is no `/status` endpoint to write to. The schema also has to declare the status fields, because the API server drops fields that the schema does not list.

Edit the CRD:

```sh
kubectl edit crd hangars.fleet.astrona.io
```

Under the version `v1`, add the subresource and the printer columns:

```yaml
    subresources:
      status: {}
    additionalPrinterColumns:
    - name: Replicas
      type: integer
      jsonPath: .spec.replicas
    - name: Ready
      type: string
      jsonPath: .status.conditions[?(@.type=="Ready")].status
```

In the schema, add the limits to `replicas` and a `status` object next to `spec`:

```yaml
              replicas:
                type: integer
                minimum: 1
                maximum: 5
```

```yaml
          status:
            type: object
            properties:
              observedGeneration:
                type: integer
              readyReplicas:
                type: integer
              conditions:
                type: array
                items:
                  type: object
                  required:
                  - type
                  - status
                  properties:
                    type:
                      type: string
                    status:
                      type: string
                    reason:
                      type: string
                    message:
                      type: string
                    observedGeneration:
                      type: integer
                    lastTransitionTime:
                      type: string
```

Check the limits with a server-side dry run. This `Hangar` must be rejected:

```sh
kubectl apply --dry-run=server -f - <<'YAML'
apiVersion: fleet.astrona.io/v1
kind: Hangar
metadata:
  name: probe-bay
  namespace: starfleet
spec:
  replicas: 9
YAML
```

The message names `spec.replicas` and the maximum. Then check that the status endpoint exists and that the listing has the new columns:

```sh
kubectl get --raw /apis/fleet.astrona.io/v1/namespaces/starfleet/hangars/scout-bay/status
kubectl -n starfleet get hangars
```

Run `astrona submit --keep`. The checks for the schema and the printer columns can pass now. The printer column check also needs `scout-bay` to be Ready, so it passes after step 4.

## Step 3: Add only the missing verb to the operator role

Confirm what the service account may do:

```sh
kubectl auth can-i create deployments.apps -n starfleet --as=system:serviceaccount:fleet-system:hangar-operator
kubectl auth can-i patch deployments.apps -n starfleet --as=system:serviceaccount:fleet-system:hangar-operator
```

The first command prints `no` and the second prints `yes`. The rule for `deployments` in the group `apps` is the third entry of the `ClusterRole`, which has the index 2. Add the verb `create`:

```sh
kubectl patch clusterrole hangar-operator --type=json \
  -p '[{"op":"replace","path":"/rules/2/verbs","value":["get","list","watch","create","patch"]}]'
```

Do not bind the service account to `cluster-admin`, `admin` or `edit`, and do not use a wildcard. Those give the operator rights it does not need, and the grader rejects them.

## Step 4: Wait for scout-bay

The operator retries every three seconds. Do not delete `scout-bay` and do not create the Deployment by hand.

```sh
kubectl -n starfleet wait --for=condition=Ready hangar/scout-bay --timeout=240s
kubectl -n starfleet get hangars
kubectl -n starfleet get deployment hangar-scout-bay -o jsonpath='{.metadata.ownerReferences[0].kind}{"\n"}'
```

The listing shows `scout-bay` with `2` in the column `REPLICAS` and `True` in the column `READY`. The last command prints `Hangar`.

## Step 5: Remove old-bay

```sh
kubectl -n starfleet get hangar old-bay -o jsonpath='{.metadata.deletionTimestamp}{"\n"}{.metadata.finalizers}{"\n"}'
```

The deletion timestamp is set and the finalizer `legacy.astrona.io/archive` is present. Nothing runs that would remove this entry, so clear it:

```sh
kubectl -n starfleet patch hangar old-bay --type=merge -p '{"metadata":{"finalizers":null}}'
kubectl -n starfleet get hangars
```

Only `scout-bay` is listed. Do not delete the CRD. Deleting it deletes every `Hangar`.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/capstone/labs/lab-01
```

All six checks must pass. Then remove the lab:

```sh
astrona destroy ats-029-capstone-010
```

## Common mistakes

- **Fixing only the permission.** `scout-bay` gets its Deployment, but the status cannot be written without the status subresource, so the grader finds no `Ready` condition.
- **Adding the status schema but not the subresource.** The status endpoint still does not exist.
- **Adding the subresource but not the status schema.** The API server drops the fields that the schema does not declare, so the status stays empty.
- **Putting the limits on the wrong field.** `minimum` and `maximum` belong on `spec.replicas`, not on `spec`.
- **Binding a broad role to the operator.** `cluster-admin`, `admin` and `edit` and wildcards fail the least-privilege check.
- **Deleting and creating `scout-bay` or the CRD again.** A new uid fails the check on `scout-bay`, and deleting the CRD removes every `Hangar`, including the objects that are checked.
- **Creating `hangar-scout-bay` by hand.** It has no owner reference to `scout-bay`.
