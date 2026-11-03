# Solution

Solve this lab on `terminal`. Each step ends with a check you can run on your own, and with `astrona submit`, which grades the lab. The `--keep` flag keeps the lab running so you can continue after a failed check. The commands below are written from the Kubernetes behaviour; you see slightly different names and times on your machine.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-020/module-03/labs/lab-01
```

## Step 1: Create the LimitRange

The field `defaultRequest` sets the request, and the field `default` sets the limit. The names are easy to swap. Save this as `limitrange-container-limits.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: outpost
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 50m
        memory: 32Mi
      default:
        cpu: 200m
        memory: 64Mi
```

Apply it:

```sh
kubectl apply -f limitrange-container-limits.yaml
```

Then check the result with a server-side dry run. It stores nothing, and it shows the pod as the API server would store it:

```sh
kubectl -n outpost run limit-check --image=busybox:1.37.0 --restart=Never --dry-run=server -o jsonpath='{.spec.containers[0].resources}{"\n"}'
```

The output shows the requests `cpu: 50m` and `memory: 32Mi` and the limits `cpu: 200m` and `memory: 64Mi`. Run `astrona submit --keep`: the check `limitrange-defaults` passes.

## Step 2: Create the ValidatingAdmissionPolicy

The policy lists `CREATE` and `UPDATE`, because a user can create a valid Deployment and then scale it up by an update. Save this as `validatingadmissionpolicy-replica-limit.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.replicas <= 3"
      message: "A Deployment may not have more than 3 replicas."
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-replica-limit.yaml
```

The policy checks nothing yet, because no binding exists. Run `astrona submit --keep`: the check `replicas-over-three-denied` still fails.

## Step 3: Bind the policy to outpost with Deny

The binding selects the namespace by its automatic label and sets the action `Deny`. Save this as `validatingadmissionpolicybinding-replica-limit-outpost.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-outpost
spec:
  policyName: replica-limit
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: outpost
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicybinding-replica-limit-outpost.yaml
```

Wait a few seconds, then check the three cases with a server-side dry run:

```sh
kubectl -n outpost create deployment bridge --image=busybox:1.37.0 --replicas=5 --dry-run=server
kubectl -n outpost create deployment bridge --image=busybox:1.37.0 --replicas=3 --dry-run=server
kubectl -n starfleet create deployment bridge --image=busybox:1.37.0 --replicas=5 --dry-run=server
```

The first command fails, and its message names `replica-limit` and `replica-limit-outpost`. The other two succeed. If the first command still succeeds, wait a little longer and repeat it. Run `astrona submit`: all four checks pass.

## Why this works

The `LimitRanger` plugin adds the default values to every new container in `outpost`, because the LimitRange lives in that namespace. The policy has no effect until the binding turns it on, and the action `Deny` makes the API server reject the request. A binding with `Warn` accepts the request and only prints a warning. The namespace selector keeps the rule out of `starfleet`, and `UPDATE` in the policy catches a change to an existing Deployment.
