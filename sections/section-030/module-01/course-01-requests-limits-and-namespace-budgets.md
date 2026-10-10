---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Requests, Limits And Namespace Budgets

The `scout` container requests 250 millicores of central processing unit (CPU) capacity and 128 mebibytes of memory. One thousand millicores equal one CPU. A request expresses resource demand used for scheduling and resource allocation decisions. The scheduler compares requests with allocatable node capacity, not just the node's current measured utilization.

A limit constrains resource use at runtime. A CPU limit can lead to throttling: the process must wait for more permitted CPU time. A container that exceeds an enforced memory limit can be terminated because it ran out of permitted memory. A memory limit is not a guarantee that the application will be healthy at that size.

Requests and limits answer different questions. A low request can permit dense placement even when actual usage becomes much higher. A very large request can leave a Pod unscheduled despite apparently idle nodes. Accurate sizing requires measurements, the application's behavior and enough headroom for its workload.

A ResourceQuota limits aggregate resource consumption or object counts in a namespace. It can reject requests that would exceed the budget. A LimitRange sets defaults and constraints for individual resources, such as container requests and limits. Neither creates node capacity. A namespace that remains within quota can still contain an unschedulable Pod.

Consider a namespace budget that allows four CPUs, while every eligible node has less than one CPU left for new requests. A new two-CPU Pod may pass quota admission but remain Pending because no single eligible node fits it. Total free capacity spread across nodes cannot always satisfy one Pod's placement requirement.

Read resource failures by identifying the stage: quota rejection happens during API admission, insufficient capacity during scheduling, and limit enforcement during execution. The same word “resources” can describe three separate mechanisms.

## A Resource-Sizing Calculation

Assume a node reports four CPUs of allocatable capacity. Existing Pods request a total of 3.5 CPUs. A new Pod requests 750 millicores, equal to 0.75 CPU. Only 0.5 CPU remains in the requested-capacity calculation, so the new Pod does not fit that node even if the current CPU graph shows low activity.

Now compare a container requesting 250 millicores with a 500-millicore CPU limit. Its request contributes 0.25 CPU to placement calculations. Its limit constrains how much CPU time it may consume under the configured runtime enforcement. The gap is not free capacity reserved exclusively for that container, and actual behavior also depends on contention and system configuration.

Memory needs different reasoning. A process can increase its memory footprint until an enforced boundary causes termination. Giving a process more CPU time does not solve an excessive memory allocation. Likewise, setting a large memory limit without a realistic request can allow dense placement that later produces node pressure.

## Admission And Placement Are Separate Budgets

Suppose a ResourceQuota permits two more CPUs in a namespace. A new Pod requests one CPU and passes quota, but all eligible nodes are already committed. The namespace budget says the team may request that amount; it does not promise a place where the Pod fits. Conversely, spare nodes do not bypass an exhausted namespace quota.

A LimitRange can provide default requests and limits when they are omitted, and it can reject values outside allowed constraints. These defaults influence the final admitted object, so the effective values may differ from what a short source snippet appears to contain. Read the stored configuration before calculating placement demand.

The three stages are admission against namespace policy, scheduling against eligible node resources and execution under runtime limits. A clear answer identifies which boundary failed and what change would address it without discarding the application's actual needs.

## Common pitfalls

> [!WARNING]
> Quotas do not reserve or create physical capacity. CPU throttling and memory termination are different consequences of runtime limits.
