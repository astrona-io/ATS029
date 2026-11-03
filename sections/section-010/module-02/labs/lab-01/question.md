# Question

Solve this question on: `terminal`

The `starfleet` team wants to describe radio beacons as Kubernetes objects. The cluster has the namespaces `starfleet` and `outpost` and no beacon type yet. Register the type and create the first beacon. `kubectl` already points at the cluster as the cluster administrator.

1. Create a CustomResourceDefinition named `beacons.signals.astrona.io` with these properties:

   - API group `signals.astrona.io`, kind `Beacon`, plural `beacons`, singular `beacon`, short name `bcn`.
   - Scope `Namespaced`.
   - One version, `v1`, that is served and is the storage version, with the status subresource enabled.

2. Give the `v1` schema a `spec` with these fields:

   - `frequencyMhz`: an integer that is required, at least `1` and at most `1000`.
   - `mode`: a string that must be `steady` or `pulse`, with the default `steady`.

   The API server must reject a `Beacon` that breaks these rules. A field that the schema does not declare must not be stored.

3. Add two printer columns so that `kubectl get beacons` shows the frequency and the mode: `Frequency` (an integer, from `.spec.frequencyMhz`) and `Mode` (a string, from `.spec.mode`).

4. After the CRD is established, create a `Beacon` named `scout-beacon` in the `starfleet` namespace with `frequencyMhz: 120` and `mode: pulse`.

Do not change the `outpost` namespace.
