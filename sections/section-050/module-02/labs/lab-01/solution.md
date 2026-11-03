# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED, so the text describes what you will see instead of pasting output.

Start the lab if it is not running:

```sh
astrona run -c .
```

## Step 1: Find why shuttle restarts

List the Pods and read the last state of the `shuttle` container:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get pods -l app=shuttle -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}{"\n"}'
```

The restart count of the `shuttle` Pod grows and the status is `CrashLoopBackOff` after the first restart. The last state reason is `OOMKilled`, so the kernel killed the container because it went over its memory limit of `32Mi`.

## Step 2: Raise the shuttle memory limit

A strategic change of the container resources keeps the rest of the Deployment. The request goes to `128Mi` and the limit to `256Mi`:

```sh
kubectl -n starfleet set resources deployment shuttle -c shuttle --requests=cpu=50m,memory=128Mi --limits=cpu=100m,memory=256Mi
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
```

The command changes the Pod template, so the Deployment starts a new rollout. Raising only the request would not help, because the limit is the number that the kernel enforces. Grade it:

```sh
astrona submit --keep
```

The `shuttle-memory-fixed` check passes after the new Pod has run for a short time without a memory kill.

## Step 3: Find what keeps scout from Guaranteed

Read the class and the resources of every container, init containers included:

```sh
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].status.qosClass}{"\n"}'
kubectl -n starfleet get deployment scout -o jsonpath='{range .spec.template.spec.initContainers[*]}{.name}{" "}{.resources}{"\n"}{end}{range .spec.template.spec.containers[*]}{.name}{" "}{.resources}{"\n"}{end}'
```

The class is `Burstable`. The init container `prepare` has no resources at all, the sidecar `metrics-agent` has a request and no limit, and the main container `scout` has requests below its limits. Any one of these is enough to stop the Pod from being `Guaranteed`.

## Step 4: Set equal requests and limits on all three containers

Edit the Deployment and set requests equal to limits on every container, including the two under `initContainers`:

```sh
kubectl -n starfleet edit deployment scout
```

Use `cpu: 10m` and `memory: 16Mi` for both requests and limits of `prepare` and `metrics-agent`, and `cpu: 100m` and `memory: 128Mi` for both requests and limits of `scout`. Save and close the editor. Wait for the rollout and read the class again:

```sh
kubectl -n starfleet rollout status deployment/scout --timeout=120s
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[*].status.qosClass}{"\n"}'
```

Every `scout` Pod is `Guaranteed` after the rollout. Grade it:

```sh
astrona submit --keep
```

## Step 5: Find why probe is Pending

```sh
kubectl -n starfleet get pods -l app=probe
kubectl -n starfleet describe pod -l app=probe
```

The Pod is `Pending`. The `Events` section at the end of the description holds a `FailedScheduling` event that says `Insufficient cpu`. The Deployment requests `cpu: "100"`, which is one hundred cores. The intended value was 100 millicores.

## Step 6: Correct the probe CPU units

```sh
kubectl -n starfleet set resources deployment probe -c probe --requests=cpu=100m,memory=64Mi --limits=cpu=200m,memory=128Mi
kubectl -n starfleet rollout status deployment/probe --timeout=120s
```

The new Pod fits on the node and becomes `Running`. Deleting the resources instead would also schedule the Pod, but it would make it `BestEffort`, and the check `resources-not-removed` rejects it. Grade it:

```sh
astrona submit
```

All five checks pass.

Clean up:

```sh
astrona destroy ats-029-lab-050-02
```
