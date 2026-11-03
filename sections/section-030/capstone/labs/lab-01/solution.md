# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is untested: command output below is described in words, and your cluster output may differ in detail.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/capstone/labs/lab-01
```

## Step 1: Find why bridge restarts

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get pods -l app=bridge -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{" "}{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
```

The `bridge` pod shows a growing restart count, and the second command prints `OOMKilled 137`. The container uses more memory than its limit of 128Mi, so the kernel ends it. Remember this for step 5.

## Step 2: Create the LimitRange first

Create the LimitRange before the quota. A quota that tracks requests refuses a pod with no requests, so the defaults must exist before the quota does. Save this as `limitrange-starfleet-limits.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: starfleet-limits
  namespace: starfleet
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
```

Apply it:

```sh
kubectl apply -f limitrange-starfleet-limits.yaml
```

Then check the result:

```sh
kubectl -n starfleet describe limitrange starfleet-limits
```

## Step 3: Create the ResourceQuota

Save this as `quota-starfleet-budget.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: starfleet-budget
  namespace: starfleet
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "6"
```

Apply it:

```sh
kubectl apply -f quota-starfleet-budget.yaml
```

Then check the result:

```sh
kubectl -n starfleet describe resourcequota starfleet-budget
```

The `Used` column counts the pods that already run. Grade the first part:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The checks `limitrange-values` and `quota-values` pass.

## Step 4: Restart probe

The running `probe` pods were admitted before the LimitRange existed, so they have no resources. New pods receive the defaults. Restart the Deployment without editing its template:

```sh
kubectl -n starfleet rollout restart deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

The new pods carry the requests 100m CPU and 128Mi memory and the limits 200m CPU and 256Mi memory. The three pods count 300m CPU and 384Mi of memory against the requests in the quota.

## Step 5: Fix bridge

The class `Guaranteed` needs CPU and memory limits with requests equal to them. The application needs about 160Mi, so use 256Mi, which is below the LimitRange maximum of 512Mi. Use 200m CPU:

```sh
kubectl -n starfleet set resources deployment bridge \
  --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n starfleet rollout status deployment/bridge --timeout=180s
kubectl -n starfleet get pods -l app=bridge -o custom-columns='NAME:.metadata.name,QOS:.status.qosClass,RESTARTS:.status.containerStatuses[0].restartCount'
```

The new pod shows `Guaranteed` and 0 restarts. The quota now shows about 500m CPU and 640Mi of memory requested, which leaves 384Mi of memory for requests. That is why a pod requesting 512Mi is refused with `exceeded quota`. Run the grader without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/capstone/labs/lab-01
```

All five checks pass. Then remove the lab:

```sh
astrona destroy ats-029-capstone-030
```
