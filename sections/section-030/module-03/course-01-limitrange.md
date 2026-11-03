---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# LimitRange: Defaults And Per-Object Limits

A ResourceQuota counts the total of a namespace, but it says nothing about one container. A team member can still create a container that asks for ten times more memory than anyone intended, or a container with no resources at all, which a quota can reject. A LimitRange (an API object of kind `LimitRange`) is the namespace policy for one object at a time. It supplies default requests and limits, and it rejects objects that are outside a minimum, a maximum or a ratio. This part writes one LimitRange and tests each rule.

## What a LimitRange does and when

The LimitRanger admission plugin runs inside the API server. It reads the LimitRange objects of the namespace when a pod or a PersistentVolumeClaim (PVC, a request for storage) is created or updated. For a pod it does two things in this order: it fills in missing requests and limits, then it checks the minimum, maximum and ratio rules. A pod that breaks a rule is rejected with Hypertext Transfer Protocol (HTTP) status 403.

The plugin acts only at admission. A LimitRange does not change pods that already run, and a changed LimitRange does not change them either. The plugin also does not check that its own defaults are consistent. A default limit can be lower than a request that a user wrote, and the pod then fails validation.

## The fields of a limit entry

One LimitRange holds a list of `limits` entries. Each entry has a `type`, which is `Container`, `Pod` or `PersistentVolumeClaim`, and a set of fields:

| Field | Meaning | Types |
| --- | --- | --- |
| `default` | The limit that a container gets when it sets none | `Container` |
| `defaultRequest` | The request that a container gets when it sets none | `Container` |
| `min` | The smallest request and limit allowed | `Container`, `Pod`, `PersistentVolumeClaim` |
| `max` | The largest limit allowed | `Container`, `Pod`, `PersistentVolumeClaim` |
| `maxLimitRequestRatio` | The largest allowed result of limit divided by request | `Container`, `Pod` |

The `Pod` type checks the sum over all containers of the pod and has no defaults. The `PersistentVolumeClaim` type checks the `storage` request. If two LimitRange objects in one namespace set different defaults, the cluster does not say which one wins, so keep one LimitRange per namespace for defaults.

## Write and apply a LimitRange

<!-- astrona:playground:renew -->

The `outpost` namespace has no policy yet. Save this as `limitrange-outpost-limits.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: outpost-limits
  namespace: outpost
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 128Mi
    defaultRequest:
      cpu: 100m
      memory: 64Mi
    min:
      cpu: 50m
      memory: 32Mi
    max:
      cpu: 500m
      memory: 256Mi
    maxLimitRequestRatio:
      cpu: "4"
  - type: PersistentVolumeClaim
    min:
      storage: 1Gi
    max:
      storage: 5Gi
```

Apply it:

```sh
kubectl apply -f limitrange-outpost-limits.yaml
```

Then check the result:

```sh
kubectl -n outpost describe limitrange outpost-limits
```

The `describe` output is a table with one row for each type and resource. It shows the minimum, maximum, default request, default limit and ratio. The running `drifter` pod is not touched, because admission happened before the LimitRange existed.

## Defaults for a pod that declares nothing

Start a pod with no `resources` section, then read what the API server stored:

```sh
kubectl -n outpost run plain --image=curlimages/curl:8.22.0 --command -- sleep 3600
kubectl -n outpost get pod plain -o jsonpath='{.spec.containers[0].resources}{"\n"}'
```

The stored pod has the requests 100m central processing unit (CPU) and 64Mi memory, and the limits 200m CPU and 128Mi memory. These are the `defaultRequest` and `default` values. The plugin also adds an annotation named `kubernetes.io/limit-ranger` to the pod that lists which values it set. Because the stored object holds the values, a later change to the LimitRange never changes this pod.

A container that sets only a limit follows a different rule. Before any admission plugin runs, the API server copies a limit into the missing request. Save this as `pod-limit-only.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: limit-only
  namespace: outpost
spec:
  containers:
  - name: limit-only
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      limits:
        cpu: 300m
        memory: 100Mi
```

Apply it and read the stored resources:

```sh
kubectl apply -f pod-limit-only.yaml
kubectl -n outpost get pod limit-only -o jsonpath='{.spec.containers[0].resources}{"\n"}'
```

The request equals the limit: 300m CPU and 100Mi memory. The `defaultRequest` of the LimitRange does not apply, because a request already exists by the time the plugin runs. This is why a pod with only limits can become Guaranteed.

## Values outside the range

Now break the rules. Save this as `pod-over-max.yaml`. It asks for 1 CPU, which is above the container maximum of 500m:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: over-max
  namespace: outpost
spec:
  containers:
  - name: over-max
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: "1"
        memory: 64Mi
      limits:
        cpu: "1"
        memory: 128Mi
```

Apply it:

```sh
kubectl apply -f pod-over-max.yaml
```

The API server answers `Forbidden`. The message contains `maximum cpu usage per Container is 500m, but limit is 1`. Change `cpu: "1"` in both places to `cpu: 20m` and apply again: the message contains `minimum cpu usage per Container is 50m, but request is 20m`. For the ratio rule, set the request to 50m and the limit to 400m. Both values are inside the range, but the limit is eight times the request, and the message says `cpu max limit to request ratio per Container is 4, but provided ratio is 8.000000`. For the claim rule, a PVC that requests 10Gi is rejected with a message that starts `maximum storage usage per PersistentVolumeClaim is 5Gi`.

Each message names the rule, the type and the allowed value, so you can fix the object without guessing. Clean up:

```sh
kubectl -n outpost delete pod plain limit-only
kubectl -n outpost delete limitrange outpost-limits
```

You now know that a LimitRange fills in missing values and then checks each object against a range, and that it never changes existing pods. The next question is what the cluster does with the requests and limits once the pod runs, which starts with the QoS class that the API server derives from them.

## Common pitfalls

> [!WARNING]
> - **Expecting a LimitRange to change running pods.** It acts at admission only. Restart the workload so new pods pass through it.
> - **Setting one value and expecting the other to follow.** A container that sets only `requests.cpu: 700m` gets the default limit of 200m, and the pod is rejected because its request is larger than its limit. Set both values when you set one.
> - **Using two LimitRange objects for defaults.** If they disagree, the result is not defined.
> - **Reading a LimitRange as a quota.** It checks one container, pod or claim. It never adds up the namespace.
