# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is untested: command output below is described in words, and your cluster output may differ in detail.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-02/labs/lab-01
```

## Step 1: Create the quota

The task gives seven hard values. `kubectl create quota` accepts them in one command:

```sh
kubectl -n starfleet create quota fleet-budget \
  --hard=requests.cpu=1,requests.memory=1Gi,limits.cpu=2,limits.memory=2Gi,pods=6,persistentvolumeclaims=2,requests.storage=3Gi
kubectl -n starfleet describe quota fleet-budget
```

The `describe` table lists seven resources. The `Used` column shows what the running `scout` and `shuttle` pods already count. The `scout` pod counts 100m CPU requests and 64Mi memory requests. The `shuttle` pods declare nothing, so they add 0. Existing pods are not removed, even though `shuttle` does not meet the new rule.

## Step 2: Give shuttle requests and limits

A quota that controls `limits.cpu` and `limits.memory` requires every new pod to declare limits as well as requests. If you set only requests, the new `shuttle` pods are refused. The Deployment is accepted, but the rollout stalls, and the events of the new ReplicaSet show `FailedCreate` with `must specify`. Set all four values:

```sh
kubectl -n starfleet set resources deployment shuttle \
  --requests=cpu=200m,memory=128Mi --limits=cpu=400m,memory=256Mi
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
```

The command ends with a line that says the Deployment `shuttle` was successfully rolled out. The total is now 700m CPU requests, 448Mi memory requests, 1400m CPU limits and 896Mi memory limits, which is below every hard value. During the rollout, one extra pod can exist, and the budget has room for it. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-02/labs/lab-01 --keep
```

The checks `quota-values` and `shuttle-fits-quota` now pass.

## Step 3: Create the claim and prove the quota refuses a second one

Save this as `pvc-logbook.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logbook
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
```

Apply it:

```sh
kubectl apply -f pvc-logbook.yaml
```

Then check the result:

```sh
kubectl -n starfleet describe quota fleet-budget
```

The claim can stay `Pending` until a pod uses it. The quota counts it already: 2Gi of 3Gi and 1 of 2 claims. Test a second claim with a server-side dry run, which creates nothing. Save this as `pvc-extra.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: extra
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
```

Run it as a dry run:

```sh
kubectl apply --dry-run=server -f pvc-extra.yaml
```

The API server answers `Forbidden` with a message that starts `exceeded quota: fleet-budget` and names `requests.storage`. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-030/module-02/labs/lab-01
```

All four checks pass. Then remove the lab:

```sh
astrona destroy ats-029-lab-030-02
```
