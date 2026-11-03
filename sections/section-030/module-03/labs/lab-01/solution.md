# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is untested: command output below is described in words, and your cluster output may differ in detail.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-03/labs/lab-01
```

## Step 1: Find why beacon restarts

Read the status of the `beacon` pod and the reason for its last termination:

```sh
kubectl -n outpost get pods -l app=beacon
kubectl -n outpost get pods -l app=beacon -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{" "}{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
```

The pod shows a growing restart count, and its status alternates between `OOMKilled` and `CrashLoopBackOff`. The second command prints `OOMKilled 137`. The container uses about 143Mi of memory for its data and the runtime needs more, so a limit of 128Mi is too small. Raising the memory request would not help, because the kill happens at the limit.

## Step 2: Create the LimitRange

Save this as `limitrange-outpost-limits.yaml`:

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
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    min:
      cpu: 50m
      memory: 64Mi
    max:
      cpu: 500m
      memory: 512Mi
    maxLimitRequestRatio:
      cpu: "4"
```

Apply it:

```sh
kubectl apply -f limitrange-outpost-limits.yaml
```

Then check the result:

```sh
kubectl -n outpost describe limitrange outpost-limits
```

The running pods are not changed, because a LimitRange acts only when a pod is created.

## Step 3: Restart drifter so it receives the defaults

The old `drifter` pod has no resources. A new pod passes through the LimitRange and receives the defaults. Restarting the Deployment creates a new pod without editing the template:

```sh
kubectl -n outpost rollout restart deployment/drifter
kubectl -n outpost rollout status deployment/drifter --timeout=180s
kubectl -n outpost get pods -l app=drifter -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

The new pod has the requests 100m CPU and 128Mi memory and the limits 200m CPU and 256Mi memory. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-03/labs/lab-01 --keep
```

The checks `limitrange-values`, `drifter-gets-defaults` and `limits-enforced` now pass.

## Step 4: Fix beacon

The class `Guaranteed` needs CPU and memory limits with requests equal to them in every container. The application needs about 160Mi, so choose 256Mi, which is below the maximum of 512Mi. Choose 200m CPU, which is inside the range and keeps the ratio at 1:

```sh
kubectl -n outpost set resources deployment beacon \
  --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n outpost rollout status deployment/beacon --timeout=180s
kubectl -n outpost get pods -l app=beacon -o custom-columns='NAME:.metadata.name,QOS:.status.qosClass,RESTARTS:.status.containerStatuses[0].restartCount'
```

The new pod shows `Guaranteed` and 0 restarts. A memory limit of 1Gi would be refused by the LimitRange maximum, so a very large limit is not a way out. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-03/labs/lab-01
```

All four checks pass. Then remove the lab:

```sh
astrona destroy ats-029-lab-030-03
```
