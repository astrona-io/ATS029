---
draft: true
exam_objectives:
- Define resource requirements
---
# Ephemeral Storage, Extended Resources And Pod-Level Resources

CPU and memory are not the only things a node can run out of. A container also writes temporary files, a cluster can offer special hardware, and a Pod with many containers may need one shared budget instead of many separate ones. Kubernetes covers these cases with three features that reuse the request and limit fields: ephemeral storage, extended resources and Pod-level resources.

## Ephemeral storage

Ephemeral storage is the temporary disk space on a node that a Pod uses and that disappears when the Pod is deleted. It includes the writable layer of each container, the container logs, and `emptyDir` volumes that are stored on disk. The resource name is `ephemeral-storage`, and it takes the same units as memory, such as `200Mi` or `1Gi`.

The two fields work like the memory fields, but the enforcement differs. The scheduler adds the requests and compares them with the node's allocatable ephemeral storage. The kubelet measures the use of every Pod on the node, and when a Pod uses more than its total ephemeral storage limit, the kubelet evicts the Pod. Eviction is not an OOM kill: the Pod is marked `Failed` with the reason `Evicted`, and a controller such as a Deployment creates a replacement Pod. The kubelet checks the usage at intervals, so eviction comes some time after the write.

Read how much ephemeral storage the playground node offers:

<!-- astrona:playground:renew -->

```sh
kubectl get nodes -o jsonpath='{.items[0].status.allocatable.ephemeral-storage}{"\n"}'
```

The value is the allocatable ephemeral storage of the node, usually in bytes. Now save a Pod that writes 100 MB into its writable layer and has a limit of 50Mi:

Save this as `pod-scout-fill.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scout-fill
  namespace: starfleet
spec:
  containers:
  - name: scout
    image: busybox:1.37.0
    command: ["sh", "-c", "dd if=/dev/zero of=/tmp/fill bs=1M count=100; sleep 3600"]
    resources:
      requests:
        cpu: 50m
        memory: 32Mi
        ephemeral-storage: 20Mi
      limits:
        cpu: 100m
        memory: 64Mi
        ephemeral-storage: 50Mi
```

Apply it:

```sh
kubectl apply -f pod-scout-fill.yaml
```

Then check the result. The kubelet needs up to a minute or two to measure the usage:

```sh
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Failed pod/scout-fill --timeout=240s
kubectl -n starfleet get pod scout-fill -o jsonpath='{.status.reason}{"\n"}{.status.message}{"\n"}'
```

The reason is `Evicted`, and the message says that the Pod ephemeral local storage usage exceeds the total limit of its containers. The container itself was not killed by the kernel, and no `OOMKilled` appears. Delete the Pod:

```sh
kubectl -n starfleet delete pod scout-fill
```

## Extended resources

An extended resource is a countable resource outside the `kubernetes.io` names, such as a special device or a license. An administrator or a device plugin advertises it by adding it to the node status. The name has a domain prefix, for example `example.com/dock`. Quantities must be whole numbers, so `500m` is not valid. Because the scheduler counts whole units, extended resources cannot be overcommitted: if you set both a request and a limit, they must be equal, and the limit alone is enough.

Advertise four units of `example.com/dock` on the node. The node status is a subresource, so the command patches `status`:

```sh
NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
kubectl patch node "$NODE_NAME" --subresource=status --type=json -p '[{"op":"add","path":"/status/capacity/example.com~1dock","value":"4"}]'
```

In the JSON Patch path, the slash inside the resource name is written as `~1`. The kubelet copies the new capacity into `allocatable` after a few seconds. Check it, and run the command again if the value is not there yet:

```sh
kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.example\.com/dock}{"\n"}'
```

Now save two Pods. The first asks for one unit and the second for five units.

Save this as `pod-probe-docks.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe-one-dock
  namespace: starfleet
spec:
  containers:
  - name: probe
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        example.com/dock: "1"
      limits:
        example.com/dock: "1"
---
apiVersion: v1
kind: Pod
metadata:
  name: probe-five-docks
  namespace: starfleet
spec:
  containers:
  - name: probe
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        example.com/dock: "5"
      limits:
        example.com/dock: "5"
```

Apply it:

```sh
kubectl apply -f pod-probe-docks.yaml
```

Then check the result:

```sh
kubectl -n starfleet get pods probe-one-dock probe-five-docks
kubectl -n starfleet describe pod probe-five-docks | sed -n '/^Events:/,$p'
```

`probe-one-dock` runs, and `probe-five-docks` stays Pending with a `FailedScheduling` event that says `Insufficient example.com/dock`. The scheduler found no node with five free units. Delete both Pods:

```sh
kubectl -n starfleet delete pod probe-one-dock probe-five-docks
```

## Pod-level resources

So far the numbers belong to containers. Pod-level resources let you write one budget for the whole Pod in `spec.resources`, which is useful when containers share a Pod and you do not want to size each one. This feature has been beta since Kubernetes 1.34 and is enabled by default. It supports CPU, memory and huge pages only. When both levels are set, the Pod-level values take precedence, and the QoS class comes from the Pod-level values.

Check that the cluster knows the field:

```sh
kubectl explain pod.spec.resources
```

The command prints the description of the `resources` field of a Pod. Save a Pod whose container sets nothing, and whose Pod sets a request and a limit:

Save this as `pod-bridge-podlevel.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bridge-podlevel
  namespace: starfleet
spec:
  resources:
    requests:
      cpu: 200m
      memory: 128Mi
    limits:
      cpu: 400m
      memory: 256Mi
  containers:
  - name: bridge
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
```

Apply it:

```sh
kubectl apply -f pod-bridge-podlevel.yaml
```

Then check the result:

```sh
kubectl -n starfleet get pod bridge-podlevel -o jsonpath='{.status.qosClass}{"\n"}{.spec.resources}{"\n"}'
kubectl -n starfleet delete pod bridge-podlevel
```

The class is `Burstable`, because the Pod-level request is below the limit, and the stored `resources` field is the budget you wrote. The scheduler uses the Pod-level request, 200m of CPU and 128Mi of memory, to place the Pod. You now know the node resources beyond CPU and memory, and the three ways to write them; what remains is a method to find the right numbers when something fails.

## Common pitfalls

> [!WARNING]
> Ephemeral storage overuse ends in eviction, not in `OOMKilled`, and the Pod status is `Failed` with the reason `Evicted`. Extended resource quantities must be whole numbers, and a request must equal the limit. A request for more units than any node advertises leaves the Pod Pending forever. A Pod-level value overrides container values, so check `spec.resources` before you blame a container.
