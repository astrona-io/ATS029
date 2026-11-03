# Question

Solve this question on: `terminal`

The platform team gives the `starfleet` namespace a fixed budget. The namespace runs the Deployment `scout` with one replica and the Deployment `shuttle` with three replicas. The `shuttle` container declares no requests and no limits. No ResourceQuota exists yet.

1. Create a ResourceQuota named `fleet-budget` in `starfleet` with exactly these hard values: `requests.cpu` 1, `requests.memory` 1Gi, `limits.cpu` 2, `limits.memory` 2Gi, `pods` 6, `persistentvolumeclaims` 2 and `requests.storage` 3Gi.

2. Change the Deployment `shuttle` so each container requests 200m CPU and 128Mi memory and is limited to 400m CPU and 256Mi memory. All three replicas must be available after the change. Do not reduce the replicas, do not delete the Deployment, and do not raise the quota. Do not change `scout`.

3. Create a PersistentVolumeClaim named `logbook` in `starfleet` that requests 2Gi with the access mode `ReadWriteOnce`. A second claim of 2Gi must be refused by the quota.

`kubectl` already points at the cluster as the cluster administrator.
