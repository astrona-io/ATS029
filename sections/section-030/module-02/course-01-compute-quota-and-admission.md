---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Compute Quota And Admission Rejection

A cluster has a fixed amount of central processing unit (CPU) and memory, and every namespace asks for a share of it. If nothing limits a namespace, one team can request all of it. A ResourceQuota (an API object of kind `ResourceQuota`) fixes the total amount of compute that all pods in one namespace may request or be limited to. This part shows what the quota counts, which component enforces it, and the two errors the API server returns when a pod does not fit.

## Which component does what

Two components work together. The ResourceQuota admission plugin runs inside the API server (`kube-apiserver`). Admission is the step after authentication and authorization where the API server can accept, change or reject a request before it stores the object. The plugin reads the quota, adds the new object's resource values to the current usage, and rejects the request with Hypertext Transfer Protocol (HTTP) status 403 (Forbidden) if the sum is above a hard value.

The resource quota controller runs inside `kube-controller-manager`. It calculates the usage of the namespace and writes it to the `status` of the quota. The plugin and the controller keep `status.used` close to the real total, but a short delay after a change is normal.

A compute quota uses these keys:

| Key | What it adds up |
| --- | --- |
| `requests.cpu` (or `cpu`) | The CPU requests of all containers in non-terminal pods |
| `requests.memory` (or `memory`) | The memory requests |
| `limits.cpu` | The CPU limits |
| `limits.memory` | The memory limits |

A pod in a terminal phase (`Succeeded` or `Failed`) no longer counts. Only the namespace of the quota is affected, and a quota never changes objects that already exist.

## Create a quota and read it

The playground namespace `starfleet` has three pods with small requests. The `scout` container requests 10m CPU and 32Mi memory, `probe` requests 10m and 16Mi, and `shuttle` requests 10m and 16Mi. The unit `m` means millicores, and 1000m is one CPU. Create a quota with `kubectl create quota`, which is the fastest way to write one on the exam.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet create quota compute-budget \
  --hard=requests.cpu=500m,requests.memory=512Mi,limits.cpu=1,limits.memory=1Gi
kubectl -n starfleet describe quota compute-budget
```

The `describe` output is a table with the columns `Resource`, `Used` and `Hard`. The `Used` column starts with the requests of the three running pods: 30m for `requests.cpu` and 64Mi for `requests.memory`. The three pods set memory limits of 64Mi, 64Mi and 32Mi, so `limits.memory` shows 160Mi. No pod sets a CPU limit, so `limits.cpu` shows 0. If a value is still 0 right after you create the quota, wait a few seconds and run the command again, because the controller needs a moment to calculate the first usage.

You can read the same numbers as data:

```sh
kubectl -n starfleet get resourcequota compute-budget -o jsonpath='{.status.hard}{"\n"}{.status.used}{"\n"}'
```

## Rejection one: a pod with no requests or limits

The `compute-budget` quota names `requests.cpu`, `requests.memory`, `limits.cpu` and `limits.memory`. When a namespace has a quota for a resource, the API server cannot add up a pod that says nothing about that resource. It rejects the pod instead. Run a pod with no `resources` section:

```sh
kubectl -n starfleet run no-resources --image=curlimages/curl:8.22.0 --command -- sleep 3600
```

The command fails with a `Forbidden` error. The message starts with `failed quota: compute-budget: must specify` and lists the resources the pod did not declare. This is a different error from an exceeded quota. Nothing is over budget; the pod simply gives the plugin no number to add. The fix is to set the values on the container, or to let a LimitRange supply defaults for them.

## Rejection two: a pod that does not fit

Now send a pod that declares everything and fits. Save this as `pod-shuttle-small.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shuttle-small
  namespace: starfleet
spec:
  containers:
  - name: shuttle
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 128Mi
```

Apply it:

```sh
kubectl apply -f pod-shuttle-small.yaml
```

Then check the result:

```sh
kubectl -n starfleet describe quota compute-budget
```

The `Used` column rises by exactly the values of the new pod: `requests.cpu` becomes 130m, `requests.memory` 128Mi, `limits.cpu` 200m and `limits.memory` 288Mi. The quota counts the declared values, not the CPU the container really uses.

Now ask for more CPU than remains. The quota allows 500m of requests and 130m are used, so a request of 600m can never fit. Save this as `pod-shuttle-large.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shuttle-large
  namespace: starfleet
spec:
  containers:
  - name: shuttle
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 600m
        memory: 64Mi
      limits:
        cpu: 600m
        memory: 128Mi
```

Apply it:

```sh
kubectl apply -f pod-shuttle-large.yaml
```

The API server answers `Forbidden` with a message that starts `exceeded quota: compute-budget`. It then names the resource that failed and gives three values: the amount requested by the new pod, the amount already used, and the limit. Read these three values first when you debug a rejection, because they tell you which key to raise or which request to lower. The pod was not stored, so `kubectl -n starfleet get pod shuttle-large` reports that it was not found.

Clean up the two objects and the quota:

```sh
kubectl -n starfleet delete pod shuttle-small
kubectl -n starfleet delete quota compute-budget
```

You now know that a compute quota adds up declared requests and limits, that the API server rejects a pod that exceeds a hard value, and that it also rejects a pod that declares nothing for a quota-controlled resource. The next question is how to limit things that are not CPU or memory, such as the number of objects and the size of volumes.

## Common pitfalls

> [!WARNING]
> - **Reading `Used` as real consumption.** The quota adds up declared requests and limits. A container that uses almost no CPU still counts its full request.
> - **Forgetting the limit keys.** A quota with `limits.memory` also requires `limits.memory` on every new pod. Pods that set only requests are rejected with `must specify`.
> - **Expecting a quota to stop existing pods.** A quota is checked when an object is created or changed. Pods that already run keep running, even if the quota is lower than their total.
> - **Treating a quota as reserved capacity.** A quota is a ceiling. It does not reserve CPU or memory on any node, and a pod that passes the quota can still stay `Pending`.
