---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Validation, Defaults, Printer Columns And Status

A CRD with a bare schema accepts almost any object that has the right field types. A team that shares a cluster needs more: the API server should reject a reading interval of zero, fill in a default level when the user leaves it out, and show the useful fields in `kubectl get`. The schema of the CRD does all of this on the server, before an object reaches etcd, so every client gets the same result. This part uses the reference CRD `telemetries.fleet.astrona.io` from the playground, breaks its rules on purpose, and adds one more rule.

## The rules in the reference schema

A `Telemetry` describes one stream of readings from a vehicle. The `spec` part of its schema has three fields, and each carries rules from the OpenAPI v3 schema language:

```yaml
spec:
  type: object
  required:
  - source
  properties:
    source:
      type: string
    intervalSeconds:
      type: integer
      minimum: 1
      maximum: 3600
      default: 60
    level:
      type: string
      enum:
      - info
      - warning
      - critical
      default: info
```

This is an excerpt of the CRD that is already applied; you do not apply it again. The keyword `required` lists the fields the user must set. The keywords `minimum` and `maximum` limit a number, `enum` limits a string to a list of values, and `default` is the value the API server writes when the user leaves the field out. The order matters: the API server applies defaults first, and then validates the object.

## Create an object that uses the defaults

Save this as `telemetry-scout.yaml`. It sets only `source`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: fleet.astrona.io/v1
kind: Telemetry
metadata:
  name: scout-readings
  namespace: starfleet
spec:
  source: scout
```

Apply it:

```sh
kubectl apply -f telemetry-scout.yaml
```

Then check the stored object and the table that `kubectl get` prints:

```sh
kubectl get telemetry scout-readings -n starfleet -o yaml
kubectl get telemetries -n starfleet
```

The YAML now contains `intervalSeconds: 60` and `level: info`, which you did not write. The API server added them from the `default` keywords. The table shows the columns `NAME`, `SOURCE`, `INTERVAL`, `LEVEL`, `PHASE` and `AGE`. The CRD defines these columns in `additionalPrinterColumns`: each entry has a `name`, a `type` and a `jsonPath` into the object. `PHASE` is empty because nothing has written `status.phase` yet. The extra columns are only a display setting of `kubectl get`; they do not change the stored object.

## Break each rule

Save this as `telemetry-bad.yaml`. It breaks three rules in one object: it has no `source`, the interval is below the minimum, and the level is not in the list:

```yaml
apiVersion: fleet.astrona.io/v1
kind: Telemetry
metadata:
  name: bad-readings
  namespace: starfleet
spec:
  intervalSeconds: 0
  level: fatal
```

Apply it:

```sh
kubectl apply -f telemetry-bad.yaml
```

The API server rejects the object and prints one error that names `Telemetry` `bad-readings` as invalid. The error lists each broken field with its path: `spec.source` is a required value, `spec.intervalSeconds` must be greater than or equal to 1, and `spec.level` is an unsupported value, with the list of allowed values. Read the field path first, because it tells you which line to fix. Nothing is stored when the request is rejected.

## Unknown fields

A schema also decides what happens to a field it does not list. Save this as `telemetry-extra.yaml`:

```yaml
apiVersion: fleet.astrona.io/v1
kind: Telemetry
metadata:
  name: extra-readings
  namespace: starfleet
spec:
  source: probe
  colour: red
```

Apply it:

```sh
kubectl apply -f telemetry-extra.yaml
```

Current `kubectl` asks the API server for strict field validation, so the server rejects the object with an error that names the unknown field `spec.colour`. Without strict validation the server does not reject unknown fields. It drops them silently, and this is called pruning. Apply the same file with strict validation switched off and read the stored object:

```sh
kubectl apply -f telemetry-extra.yaml --validate=false
kubectl get telemetry extra-readings -n starfleet -o jsonpath='{.spec}'
```

The stored `spec` has `source` and the defaults, but no `colour`. The server removed the field because the schema does not declare it. A CRD author can switch pruning off for one object with `x-kubernetes-preserve-unknown-fields: true`, but then the server stores any data a client sends. Prefer to declare every field.

## Add a validation rule with CEL

Some rules cannot be written with types and ranges, because they compare two fields. The Common Expression Language (CEL) lets a CRD hold such a rule in `x-kubernetes-validations`. Each entry has a `rule` that must be true and a `message` that the user sees when it is false. The rule below says that a `critical` stream must send a reading at least every 60 seconds.

Save this as `cel-patch.yaml`. It is a JSON patch that adds the rule to the `spec` schema:

```yaml
- op: add
  path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/x-kubernetes-validations
  value:
  - rule: self.level != 'critical' || self.intervalSeconds <= 60
    message: critical readings need intervalSeconds of 60 or less
```

Apply it to the CRD:

```sh
kubectl patch crd telemetries.fleet.astrona.io --type=json --patch-file cel-patch.yaml
```

In a rule, `self` is the object at the place where the rule sits, here the `spec`. Now try an object that breaks the rule. Save this as `telemetry-critical.yaml`:

```yaml
apiVersion: fleet.astrona.io/v1
kind: Telemetry
metadata:
  name: critical-readings
  namespace: starfleet
spec:
  source: shuttle
  level: critical
  intervalSeconds: 300
```

Apply it:

```sh
kubectl apply -f telemetry-critical.yaml
```

The API server rejects the object and prints your message, `critical readings need intervalSeconds of 60 or less`. Change `intervalSeconds` to `30` and apply again, and the object is accepted. The API server checks the rule on every create and update of a `Telemetry`. It runs inside the API server, so no webhook or extra component is needed.

## Status is a separate part of the object

The reference CRD has `subresources.status: {}`. This enables a second endpoint, `/status`, for the `status` field. The effect is a separation: a normal update or patch of the object ignores the `status` field, and an update of the `/status` endpoint ignores everything except `status`. The separation matters because users own `spec` and controllers own `status`, and a controller needs its own permission on the status endpoint.

Compare the two patches. First patch the whole object:

```sh
kubectl patch telemetry scout-readings -n starfleet --type=merge -p '{"status":{"phase":"Lost"}}'
kubectl get telemetry scout-readings -n starfleet -o jsonpath='{.status}'
```

The patch command reports that nothing changed, and the second command prints nothing, because the main endpoint dropped the `status` field. Now patch the status endpoint:

```sh
kubectl patch telemetry scout-readings -n starfleet --subresource=status --type=merge -p '{"status":{"phase":"Active"}}'
kubectl get telemetries -n starfleet
```

The `PHASE` column now shows `Active`. A change of `spec` also increases `metadata.generation`, and a change of `status` does not. That is how a controller tells a new request from its own report.

You now know how the schema validates, defaults and prunes objects, how CEL adds a rule that compares fields, and why `status` has its own endpoint. The remaining question is what happens when the CRD itself must change after users already created objects.

## Common pitfalls

> [!WARNING]
> - **Reading `required` and `default` as one rule.** A field with a `default` is filled in before validation, so it is never reported as missing. `required` only reports a field that has no default.
> - **Expecting `kubectl` to prune unknown fields.** Current `kubectl` rejects them. Pruning happens when strict validation is off, and the data is lost without any message.
> - **Patching `status` through the main endpoint.** The change is ignored when the CRD enables the status subresource. Use `--subresource=status`.
> - **Writing a CEL rule on an optional field without a default.** The rule fails when the field is absent. Give the field a default or test it with `has(self.field)`.
> - **Trusting printer columns as data.** They only change what `kubectl get` prints. A wrong `jsonPath` shows an empty column, not an error.
