# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED, so the text describes what you will see instead of pasting output.

Start the lab if it is not running:

```sh
astrona run -c .
```

## Step 1: Read why drifter has no Pods

```sh
kubectl -n outpost get deployment drifter
kubectl -n outpost get events --field-selector reason=FailedCreate
kubectl -n outpost describe quota outpost-quota
```

The Deployment has 0 of 2 ready replicas. The `FailedCreate` events come from the ReplicaSet. They say that the quota refuses the Pods because they must specify limits and requests. The quota description shows that `beacon` already uses `limits.cpu` 2 of 2.

## Step 2: Create the LimitRange

Save this as `limitrange-outpost-defaults.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: outpost-defaults
  namespace: outpost
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 128Mi
      ephemeral-storage: 200Mi
    defaultRequest:
      cpu: 100m
      memory: 64Mi
      ephemeral-storage: 50Mi
    max:
      cpu: 500m
      memory: 256Mi
```

Apply it:

```sh
kubectl apply -f limitrange-outpost-defaults.yaml
```

Then check the result:

```sh
kubectl -n outpost describe limitrange outpost-defaults
astrona submit --keep
```

The `limitrange-defaults` check passes. The new Pods of `drifter` still fail, because `beacon` holds the whole CPU limit quota.

## Step 3: Lower the beacon limits

```sh
kubectl -n outpost set resources deployment beacon -c beacon --requests=cpu=100m,memory=64Mi --limits=cpu=400m,memory=128Mi
kubectl -n outpost rollout status deployment/beacon --timeout=120s
```

The `beacon` Deployment uses the `Recreate` strategy, so the old Pod stops before the new one starts, and the quota has room for the new Pod. The new `beacon` Pod is created under the LimitRange, so it also gets the default ephemeral storage values. Grade it:

```sh
astrona submit --keep
```

## Step 4: Restart drifter

A ReplicaSet retries a refused Pod with a growing delay. A new rollout creates a new ReplicaSet at once:

```sh
kubectl -n outpost rollout restart deployment/drifter
kubectl -n outpost rollout status deployment/drifter --timeout=120s
kubectl -n outpost get pod -l app=drifter -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

The two Pods run, and the stored resources are the defaults of the LimitRange: a CPU request of 100m and a limit of 200m. Grade it:

```sh
astrona submit --keep
```

## Step 5: Add the ephemeral storage caps to the quota

```sh
kubectl -n outpost patch resourcequota outpost-quota -p '{"spec":{"hard":{"requests.ephemeral-storage":"1Gi","limits.ephemeral-storage":"2Gi"}}}'
kubectl -n outpost describe quota outpost-quota
```

The patch merges the two new entries and keeps the other values. The quota table now lists the ephemeral storage rows. Every active Pod has ephemeral storage values, because the LimitRange added them. Grade it:

```sh
astrona submit
```

All five checks pass.

Clean up:

```sh
astrona destroy ats-029-lab-050-03
```
