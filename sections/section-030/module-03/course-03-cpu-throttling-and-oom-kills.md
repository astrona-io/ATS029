---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# CPU Throttling And OOMKilled

A limit is a promise that the node enforces, not a hint. The way it is enforced depends on the resource. CPU time can be shared out again a moment later, so a container that wants more than its limit is slowed down. Memory cannot be taken back from a process once it is allocated, so a container that goes over its limit is stopped. This part shows both outcomes on a running pod and the status fields that prove which one happened.

## How the node enforces CPU

The kubelet (the agent on each node) passes the requests and limits to the container runtime, and the runtime writes them into the Linux control group (cgroup) of the container. A cgroup is the kernel feature that groups processes and limits their resources.

A CPU request becomes a relative weight. When the processes on a node compete for CPU time, the kernel shares the time in proportion to the weights. When nobody competes, a container can use more than its request. A CPU limit becomes a quota: the container may use a fixed amount of CPU time in every scheduling period of 100 milliseconds. A limit of 100m means 10 milliseconds of CPU time in every period. When the container has used its time, the kernel pauses it until the next period. This pause is called throttling. The process is slower, but it is never killed for using too much CPU.

## Watch throttling happen

Start a pod that uses all the CPU it can get, with a limit of 100m. The pod runs a loop in a shell and does nothing else. Save this as `pod-spin.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: spin
  namespace: starfleet
spec:
  containers:
  - name: spin
    image: curlimages/curl:8.22.0
    command: ["sh", "-c", "while true; do :; done"]
    resources:
      requests:
        cpu: 50m
        memory: 16Mi
      limits:
        cpu: 100m
        memory: 32Mi
```

Apply it:

```sh
kubectl apply -f pod-spin.yaml
kubectl -n starfleet wait --for=condition=Ready pod/spin --timeout=120s
```

Then read the throttling counters that the kernel keeps for the container. On a node that uses cgroup version 2, the file is `/sys/fs/cgroup/cpu.stat` inside the container:

```sh
kubectl -n starfleet exec spin -- cat /sys/fs/cgroup/cpu.stat
```

The file has the counters `nr_periods`, `nr_throttled` and `throttled_usec`. Because the loop always wants more CPU, `nr_throttled` is a positive number that grows each time you run the command. The pod stays `Running` and its restart count stays at 0. If the file does not exist, the node uses cgroup version 1, where the same counters are in `/sys/fs/cgroup/cpu/cpu.stat`.

A throttled application shows slow responses, not errors. If a service gets slow when it is busy, and its pod has a CPU limit, throttling is a likely cause. Raising the CPU limit or removing it is the fix. Delete the pod:

```sh
kubectl -n starfleet delete pod spin
```

## How the node enforces memory

A memory request is used only for scheduling and for ordering eviction. A memory limit becomes a hard maximum in the cgroup. When the processes in the container try to use more memory than the limit and the kernel cannot reclaim enough, the kernel Out Of Memory (OOM) killer ends a process in that cgroup. The kubelet then sees that the container stopped. It records the reason `OOMKilled` and the exit code 137, which is 128 plus signal 9 (`SIGKILL`).

What happens next follows the pod's `restartPolicy`. The default is `Always`, so the kubelet starts the container again. If the container keeps dying, the kubelet waits longer between starts, and the pod status shows `CrashLoopBackOff`. The pod object is still the same pod: the restart count grows, and the container state alternates between waiting and terminated.

## Watch an OOM kill

The container below allocates about 200 megabytes of memory and has a limit of 100Mi. Save this as `pod-memory-hog.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
  namespace: starfleet
spec:
  containers:
  - name: hog
    image: docker.io/library/python:3.13-alpine
    command: ["python", "-c", "data = b'x' * 200000000; import time; time.sleep(3600)"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 100Mi
```

Apply it:

```sh
kubectl apply -f pod-memory-hog.yaml
```

Wait about half a minute, then read the pod and the reason for the last termination:

```sh
kubectl -n starfleet get pod memory-hog
kubectl -n starfleet get pod memory-hog -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}{" "}{.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
```

The first command shows a status of `OOMKilled` or `CrashLoopBackOff` and a growing `RESTARTS` count. The second prints `OOMKilled 137`. The field `lastState.terminated.reason` is the proof: the container was not stopped by a failed probe or by its own error. Compare `kubectl describe pod memory-hog`, which prints the same reason and exit code in the `Last State` block.

Restarting does not fix the problem, because every start allocates the memory again. The cause is the limit, so the fix is a larger limit, or a smaller memory demand in the application. Container resources are normally changed by creating a new pod, so you delete this pod and apply a changed one. For a Deployment, you edit the pod template and the Deployment replaces the pods. Delete the test pod:

```sh
kubectl -n starfleet delete pod memory-hog
```

## Telling the two outcomes apart

CPU and memory differ because CPU is a rate and memory is an amount. A container over its CPU limit waits and then continues. A container over its memory limit loses the process. A larger CPU request does not prevent an OOM kill, and a larger memory request does not prevent throttling. Read `lastState.terminated.reason` for the kill, and read the cgroup counters or the response times for throttling.

You now know how each limit is enforced and how to prove an OOM kill from the pod status. The remaining failures happen before a container runs, when the scheduler cannot find a node, and while many pods share a node that runs short of memory.

## Common pitfalls

> [!WARNING]
> - **Expecting a CPU limit to kill a container.** The container is slowed down, never stopped, for using too much CPU.
> - **Raising the memory request to stop `OOMKilled`.** The kill happens at the limit. Raise `limits.memory`.
> - **Reading `CrashLoopBackOff` as the cause.** It only says that the container keeps stopping. Read `lastState.terminated.reason` and the exit code to find why.
> - **Setting a memory limit equal to the average use.** A short peak above the limit is enough for a kill. Leave headroom above measured peaks.
