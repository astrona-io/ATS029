# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED, so the text describes what you will see instead of pasting output.

Start the lab if it is not running:

```sh
astrona run -c .
```

## Step 1: Fix the bridge memory limit

```sh
kubectl -n starfleet get pods -l app=bridge -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{"\n"}'
kubectl -n starfleet set resources deployment bridge -c bridge --requests=cpu=50m,memory=128Mi --limits=cpu=100m,memory=256Mi
kubectl -n starfleet rollout status deployment/bridge --timeout=120s
```

The last state reason is `OOMKilled`, because the limit was `32Mi`. After the change, the new Pod runs. Grade it:

```sh
astrona submit --keep
```

## Step 2: Find why scout has no Pods

```sh
kubectl -n starfleet get events --field-selector reason=FailedCreate
kubectl -n starfleet describe quota starfleet-quota
```

The events come from the ReplicaSet of `scout` and say that the Pod exceeds the quota for `requests.cpu`. The Pod needs the effective request: the sidecar `log-shipper` runs together with the main container, so the sum is 900m plus 200m, which is 1100m. The quota allows 1 CPU in total for the namespace.

## Step 3: Right-size scout

Edit the Deployment:

```sh
kubectl -n starfleet edit deployment scout
```

Set the `log-shipper` CPU request and limit to `100m`. Give the `prepare` init container CPU and memory requests and limits of `10m` and `16Mi`. Keep the main container as it is. All three containers now have equal requests and limits, so the Pod can be `Guaranteed`. The new effective CPU request is 300m, which is the sidecar plus the main container. Check the result:

```sh
kubectl -n starfleet rollout status deployment/scout --timeout=120s
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].status.qosClass}{"\n"}'
```

The class is `Guaranteed`. If the first Pod is not created yet, the ReplicaSet is waiting between retries; restart the Deployment with `kubectl -n starfleet rollout restart deployment/scout`. Grade it:

```sh
astrona submit --keep
```

## Step 4: Create the LimitRange for shuttle

Save this as `limitrange-starfleet-defaults.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: starfleet-defaults
  namespace: starfleet
spec:
  limits:
  - type: Container
    default:
      cpu: 100m
      memory: 64Mi
    defaultRequest:
      cpu: 50m
      memory: 32Mi
    max:
      cpu: 500m
      memory: 512Mi
```

Apply it:

```sh
kubectl apply -f limitrange-starfleet-defaults.yaml
```

Then check the result. A new rollout makes the ReplicaSet create the Pod at once:

```sh
kubectl -n starfleet rollout restart deployment/shuttle
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
kubectl -n starfleet get pod -l app=shuttle -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

The Pod runs with the default requests and limits from the LimitRange. Grade it:

```sh
astrona submit
```

All five checks pass.

Clean up:

```sh
astrona destroy ats-029-capstone-050
```
