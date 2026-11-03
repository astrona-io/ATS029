---
draft: true
exam_objectives:
- Define resource requirements
---
# Quality Of Service And Node Allocation

A node has a fixed amount of CPU and memory. The scheduler fills it with Pods up to the total of their requests, and the limits are allowed to add up to more than the node has. When the Pods really use more memory than the node holds, Kubernetes must stop some of them. This part explains how Kubernetes picks which ones, and how you read the numbers the scheduler uses.

## The three quality of service classes

Kubernetes gives every Pod a quality of service (QoS) class when the API server creates it. The class comes from the resource settings in the Pod specification, and you cannot set it directly. The API server stores it in `status.qosClass`.

- **Guaranteed**: every container, including every init container, has a CPU limit, a memory limit, and requests equal to its limits. If you set only the limits, Kubernetes copies them into the requests, and the Pod is still Guaranteed.
- **Burstable**: the Pod is not Guaranteed, and at least one container has a CPU or memory request or limit.
- **BestEffort**: no container has any CPU or memory request or limit.

The class matters when a node runs out of memory. The kubelet first tries to evict Pods (stop them and mark them failed) when the node crosses a memory pressure threshold. It evicts BestEffort Pods first, then Burstable Pods that use more than they requested, and it touches Guaranteed Pods last. At the kernel level, the kubelet also sets the OOM score of each container: Guaranteed containers get -997 (the kernel kills them last), BestEffort containers get 1000 (the kernel kills them first), and Burstable containers get a value in between that is lower when the container requests more memory.

## Read the classes of three running Deployments

The playground starts three Deployments in `starfleet`. `scout` sets requests equal to limits, `probe` sets requests below limits, and `shuttle` sets nothing. List the class of each Pod with a custom column:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

The `scout` Pod is `Guaranteed`, the `probe` Pod is `Burstable`, and the `shuttle` Pod is `BestEffort`. You can confirm the reason by reading the settings:

```sh
kubectl -n starfleet get deployment scout probe shuttle -o custom-columns=NAME:.metadata.name,RESOURCES:.spec.template.spec.containers[0].resources
```

The `shuttle` column is empty because the container has no `resources` field. This also shows a common wrong belief: a Pod with no settings is not "neutral". It is the first candidate for eviction.

## Predict the class from limits only

Save a Pod that sets only limits. It is a good exam exercise, because the rule that requests default to limits is easy to forget.

Save this as `pod-probe-limits-only.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe-limits-only
  namespace: starfleet
spec:
  containers:
  - name: probe
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      limits:
        cpu: 100m
        memory: 64Mi
```

Apply it:

```sh
kubectl apply -f pod-probe-limits-only.yaml
```

Then check the result:

```sh
kubectl -n starfleet get pod probe-limits-only -o jsonpath='{.status.qosClass}{"\n"}{.spec.containers[0].resources}{"\n"}'
```

The class is `Guaranteed`, and the stored `resources` field shows requests equal to the limits. The API server filled in the requests when it admitted the Pod. If you set a memory request but no CPU setting at all, the Pod would be Burstable, because the Guaranteed rule needs both resources on every container.

## How a node adds up requests

The scheduler compares the sum of the requests of the Pods on a node with the node's **allocatable** amount. Allocatable is the part of the node's **capacity** that Pods may use. It is the capacity minus the amounts reserved for the operating system and the kubelet, and minus the eviction threshold. Read both values from the node:

```sh
kubectl get nodes -o jsonpath='{.items[0].status.capacity}{"\n"}{.items[0].status.allocatable}{"\n"}'
```

Now read the node's own view of what is reserved:

```sh
kubectl describe node | sed -n '/^Allocated resources:/,/^Events:/p'
```

The section `Allocated resources` lists the total requests and the total limits of all Pods on the node, each with a percentage of allocatable. The percentage of requests is the number that decides whether a new Pod fits. The percentage of limits may be above 100, because limits are allowed to overcommit the node. The table `Non-terminated Pods` above it lists each Pod with its own requests and limits, so you can find which Pod holds the most capacity.

## When a Pod does not fit

If no node has enough unreserved capacity for the Pod's requests, the scheduler leaves the Pod in the `Pending` phase and records a `FailedScheduling` event. Save a Pod that asks for more memory than any node has:

Save this as `pod-bridge-large.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bridge-large
  namespace: starfleet
spec:
  containers:
  - name: bridge
    image: busybox:1.37.0
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 100m
        memory: 1000Gi
```

Apply it:

```sh
kubectl apply -f pod-bridge-large.yaml
```

Then check the result:

```sh
kubectl -n starfleet get pod bridge-large
kubectl -n starfleet describe pod bridge-large | sed -n '/^Events:/,$p'
```

The Pod stays `Pending`. The event has the reason `FailedScheduling`, and its message says how many nodes were checked and names the resource that was short, here `Insufficient memory`. The node's actual memory use plays no part: the scheduler only compares requests with allocatable. Delete the Pods you created:

```sh
kubectl -n starfleet delete pod probe-limits-only bridge-large
```

## Compare requests with real usage

The command `kubectl top pod` and `kubectl top node` show the live usage that the metrics server (an add-on that collects CPU and memory use from every kubelet) reports. It is the tool for comparing what a Pod uses with what it requests. The playground does not install the metrics server, so the command answers that the Metrics API is not available. On an exam cluster where the metrics server runs, use `kubectl top pod -n starfleet --containers` to see each container, and `kubectl top node` for the nodes. The numbers show use at the moment of the sample, not the peak, so repeat the command under load before you choose a limit.

You now know how a Pod gets its class, how the node's allocatable amount is spent by requests, and why a Pending Pod with `Insufficient` in its event is a request problem. The remaining question is how the requests add up when a Pod also has init containers and a sidecar.

## Common pitfalls

> [!WARNING]
> A Pod is Guaranteed only if every container, including init containers, has equal requests and limits for both CPU and memory. One container with only a memory limit makes the whole Pod Burstable. The `Allocated resources` percentage counts requests, so a node can be nearly empty in `kubectl top` and still be full for the scheduler. Pods without any settings are BestEffort and are evicted first.
