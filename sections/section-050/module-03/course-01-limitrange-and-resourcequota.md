---
draft: true
exam_objectives:
- Define resource requirements
---
# LimitRange And ResourceQuota

A developer who writes the resource settings of one Pod controls only that Pod. A cluster shared by many teams needs rules for the whole namespace: a default for containers that set nothing, a ceiling for a single container, and a cap for the sum of everything the namespace uses. Kubernetes provides two objects for this, the LimitRange and the ResourceQuota, and both act when the API server admits an object.

## LimitRange: defaults and limits per container

A LimitRange is a namespaced object that sets resource rules for each container (or each Pod) created in that namespace. Its fields for a rule of type `Container` are:

- `default`: the limit given to a container that has no limit.
- `defaultRequest`: the request given to a container that has no request.
- `min` and `max`: the smallest and largest value allowed for a request or limit.
- `maxLimitRequestRatio`: the largest allowed ratio between a limit and a request.

The LimitRanger admission plugin in the API server applies the rule when a Pod is created. It first fills missing values, and then checks the result against `min` and `max`. A container that breaks a rule makes the API server refuse the Pod with a `Forbidden` error that names the rule. A LimitRange changes only Pods created after it exists; Pods that already run keep their old values.

The playground has a LimitRange in `outpost`. Read it:

<!-- astrona:playground:renew -->

```sh
kubectl -n outpost describe limitrange outpost-defaults
```

The output is a table with one row per resource. For `cpu`, `memory` and `ephemeral-storage`, the columns show the minimum, the maximum, the default request, the default limit and the ratio. Here a container with no settings gets a CPU request of 100m and a limit of 200m, and no container may ask for more than 500m of CPU or 256Mi of memory.

## See a default applied

Create a Pod with no resource settings and read what the API server stored. The command `kubectl run` creates a single Pod, and `--command --` makes everything after it the container command.

```sh
kubectl -n outpost run scout-plain --image=busybox:1.37.0 --command -- sleep 3600
kubectl -n outpost get pod scout-plain -o jsonpath='{.spec.containers[0].resources}{"\n"}'
```

The Pod specification now holds the default requests and limits from the LimitRange, although the command set none. The Pod also carries the annotation `kubernetes.io/limit-ranger`, which lists which values the LimitRanger plugin set. The Pod is therefore Burstable, not BestEffort.

Now break the maximum. Save a Pod that asks for two CPUs:

Save this as `pod-scout-large.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scout-large
  namespace: outpost
spec:
  containers:
  - name: scout
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: "2"
        memory: 128Mi
```

Apply it:

```sh
kubectl apply -f pod-scout-large.yaml
```

The API server answers at once with an error from the LimitRange. It says that the maximum CPU usage per container is 500m, but the limit is 2. The Pod object is not created, so nothing is Pending and no event exists: the rejection happens in admission, before the scheduler sees the Pod.

## ResourceQuota: a cap for the whole namespace

A ResourceQuota is a namespaced object with a `spec.hard` map. Each entry is a ceiling for the namespace total. You can cap compute resources (`requests.cpu`, `requests.memory`, `limits.cpu`, `limits.memory`, `requests.ephemeral-storage`) and object counts (`pods`, `services`, `persistentvolumeclaims`, `count/deployments.apps`). The quota controller tracks the current use and stores it in `status.used`. The admission plugin ResourceQuota runs after the LimitRanger and rejects a request that would push `used` above `hard`.

Two consequences matter for developers. First, if a quota covers `requests.cpu` or `limits.memory`, every new Pod must state that value, or the API server refuses it. A LimitRange default solves this for containers that set nothing. Second, a quota does not move or stop existing Pods; it only blocks new ones. You can create a quota quickly with `kubectl create quota outpost-quota --hard=cpu=1,memory=1Gi,pods=6`, where `cpu` and `memory` are short names for the request totals.

Read the quota of `outpost`:

```sh
kubectl -n outpost describe quota outpost-quota
```

The table lists each resource with its `Used` and `Hard` values. The `pods` row shows a hard limit of 6.

## A quota reaches a Deployment through its ReplicaSet

When a controller creates the Pods, the rejection does not appear on your command. The Deployment is accepted, its ReplicaSet tries to create each Pod, and the API server refuses the ones that exceed the quota. Save a Deployment that asks for eight replicas, without resource settings:

Save this as `deployment-drifter-extra.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: drifter-extra
  namespace: outpost
spec:
  replicas: 8
  selector:
    matchLabels:
      app: drifter-extra
  template:
    metadata:
      labels:
        app: drifter-extra
    spec:
      containers:
      - name: drifter
        image: busybox:1.37.0
        command: ["sh", "-c", "sleep 3600"]
```

Apply it:

```sh
kubectl apply -f deployment-drifter-extra.yaml
```

Then check the result:

```sh
kubectl -n outpost get deployment drifter-extra
kubectl -n outpost get events --field-selector reason=FailedCreate
kubectl -n outpost describe quota outpost-quota
```

The Deployment shows fewer ready replicas than the eight you asked for. The `FailedCreate` events come from the ReplicaSet, and each message says `exceeded quota: outpost-quota` with the requested, used and limited values for `pods`. The quota shows 6 of 6 pods used. The LimitRange supplied the missing requests, so the Pods themselves passed admission. Only the Pod count was too high.

With the quota full, a direct creation fails immediately:

```sh
kubectl -n outpost run scout-extra --image=busybox:1.37.0 --command -- sleep 60
```

The command ends with a `Forbidden` error that names `outpost-quota`. Clean up:

```sh
kubectl -n outpost delete deployment drifter-extra
kubectl -n outpost delete pod scout-plain
```

You can now place each failure: a LimitRange or quota breach on a direct Pod is an immediate error, the same breach in a Deployment is a `FailedCreate` event on the ReplicaSet, and a Pod that was admitted but fits no node is Pending. The next question is what the node can hold besides CPU and memory.

## Common pitfalls

> [!WARNING]
> A new LimitRange does not change Pods that already run, and a new quota does not remove existing Pods. A quota on requests or limits makes those fields required, so a Pod without them is refused unless a LimitRange default fills them in. When a Deployment seems stuck at fewer replicas than requested, read the ReplicaSet events, not the Deployment status.
