# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01
```

## Step 1: Register the type

Write the whole CRD in one file. The name must be the plural and the group joined by a dot. The scope `Namespaced` gives every `Beacon` a namespace, and `subresources.status: {}` enables the status endpoint.

Save this as `beacon-crd.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: beacons.signals.astrona.io
spec:
  group: signals.astrona.io
  scope: Namespaced
  names:
    plural: beacons
    singular: beacon
    kind: Beacon
    listKind: BeaconList
    shortNames:
    - bcn
  versions:
  - name: v1
    served: true
    storage: true
    subresources:
      status: {}
    additionalPrinterColumns:
    - name: Frequency
      type: integer
      jsonPath: .spec.frequencyMhz
    - name: Mode
      type: string
      jsonPath: .spec.mode
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required:
            - frequencyMhz
            properties:
              frequencyMhz:
                type: integer
                minimum: 1
                maximum: 1000
              mode:
                type: string
                enum:
                - steady
                - pulse
                default: steady
          status:
            type: object
            properties:
              phase:
                type: string
```

The rules are in the schema. `required` sits on the `spec` object and lists `frequencyMhz`. `minimum` and `maximum` limit the number. `enum` limits `mode` to two strings, and `default` fills in `steady` when the user leaves `mode` out. The schema declares every field, so the API server drops anything else. The printer columns come from the two `jsonPath` values.

Apply it:

```sh
kubectl apply -f beacon-crd.yaml
```

Then wait until the API server serves the type:

```sh
kubectl wait --for=condition=Established crd/beacons.signals.astrona.io --timeout=60s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01 --keep
```

The checks `crd-registered`, `schema-rules-enforced`, `unknown-fields-dropped` and `printer-columns` now pass, except that `printer-columns` still needs the object from the next step. If `schema-rules-enforced` fails, test the rule yourself with a dry run in step 3.

## Step 2: Create the Beacon

Save this as `scout-beacon.yaml`:

```yaml
apiVersion: signals.astrona.io/v1
kind: Beacon
metadata:
  name: scout-beacon
  namespace: starfleet
spec:
  frequencyMhz: 120
  mode: pulse
```

Apply it:

```sh
kubectl apply -f scout-beacon.yaml
```

Then check it with the short name and the table:

```sh
kubectl get bcn -n starfleet
kubectl get beacons -n starfleet
```

Both commands show `scout-beacon` with the columns `FREQUENCY` and `MODE`. Grade it again:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01 --keep
```

## Step 3: Test the rules yourself

A server-side dry run sends the object through validation and defaulting and stores nothing. Save this as `bad-beacon.yaml`:

```yaml
apiVersion: signals.astrona.io/v1
kind: Beacon
metadata:
  name: bad-beacon
  namespace: starfleet
spec:
  frequencyMhz: 0
  mode: chirp
```

Send it as a dry run:

```sh
kubectl apply -f bad-beacon.yaml --dry-run=server
```

The API server rejects the object and lists two errors: `spec.frequencyMhz` is below the minimum and `spec.mode` is an unsupported value. Change `frequencyMhz` to `500`, remove the `mode` line and run the command again. The dry run is accepted, and `kubectl apply -f bad-beacon.yaml --dry-run=server -o yaml` shows `mode: steady`, the default.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-010/module-02/labs/lab-01
```

All five checks must pass. Then remove the lab:

```sh
astrona destroy ats-029-lab-010-02
```

## Common mistakes

- **Wrong CRD name.** `beacon.signals.astrona.io` or `beacons.astrona.io` is rejected. The name is `<plural>.<group>`.
- **Creating the Beacon before the CRD is `Established`.** The API server answers that it does not know the kind `Beacon`. Wait for the condition first.
- **Putting `default` on the `spec` object.** The default for `mode` belongs on the `mode` field.
- **Setting `x-kubernetes-preserve-unknown-fields: true` to avoid errors.** The server then stores any field, and the check `unknown-fields-dropped` fails.
- **Enabling the status subresource with `status: true`.** The value is an empty object, written as `status: {}`.
