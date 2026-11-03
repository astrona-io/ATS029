---
draft: true
exam_objectives:
- Understand requests, limits, quotas
---
# Object Count And Storage Quotas

Central processing unit (CPU) and memory are not the only things a namespace can use up. Each pod, Service, Secret and ConfigMap is stored in etcd, the database behind the API server, and a namespace that creates thousands of them slows the control plane down. Each volume claim takes storage from the cluster. A ResourceQuota can limit both, and this part shows the keys, the exam-style commands and the way a limit can apply to one storage class only.

## Object count keys

An object count quota limits how many objects of one kind exist in the namespace. Two key styles exist. The generic style is `count/<resource>.<group>`, and it works for any namespaced resource, including custom resources. For core resources the group is empty, so the key is `count/secrets`. For the `apps` group the key is `count/deployments.apps`, and for jobs it is `count/jobs.batch`.

The older style uses a bare name and exists only for a fixed list: `pods`, `services`, `secrets`, `configmaps`, `persistentvolumeclaims`, `replicationcontrollers` and `resourcequotas`. There are also two Service variants, `services.nodeports` and `services.loadbalancers`. The `pods` key counts only pods that are not in a terminal phase.

An object count quota needs no requests or limits on the objects. It only counts them. The count applies to every object, including those that a controller creates for you.

## Create an object count quota

The `starfleet` namespace has three Deployments (`scout`, `probe`, `shuttle`) and two Services (`scout` and `probe`). It also holds one ConfigMap named `kube-root-ca.crt`, which the cluster publishes into every namespace. These objects count against a new quota from the first moment.

<!-- astrona:playground:renew -->

Save this as `quota-object-budget.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-budget
  namespace: starfleet
spec:
  hard:
    configmaps: "3"
    services: "3"
    count/deployments.apps: "4"
```

Apply it:

```sh
kubectl apply -f quota-object-budget.yaml
```

Then check the result:

```sh
kubectl -n starfleet describe quota object-budget
```

The table shows 1 of 3 ConfigMaps, 2 of 3 Services and 3 of 4 Deployments in use. Quantities in a quota are strings, so numbers are quoted in YAML. Now create objects until one is refused. Two ConfigMaps fit, and the third does not.

```sh
kubectl -n starfleet create configmap crew-roster --from-literal=captain=unassigned
kubectl -n starfleet create configmap crew-shifts --from-literal=night=bridge
kubectl -n starfleet create configmap crew-extra --from-literal=spare=yes
```

The first two commands succeed. The third fails with `Forbidden` and a message that starts `exceeded quota: object-budget` and names `configmaps` with the requested, used and limited values. Count quotas reject on the object, so the cause is always the number of objects of that kind, not their size.

## Storage keys

A storage quota limits the capacity that PersistentVolumeClaims (PVCs) request. A PVC is a request for storage made by a user, and a PersistentVolume (PV) is the storage that satisfies it. The keys are:

| Key | What it limits |
| --- | --- |
| `requests.storage` | The sum of the storage requested by all PVCs in the namespace |
| `persistentvolumeclaims` | The number of PVCs |
| `<class>.storageclass.storage.k8s.io/requests.storage` | The storage requested by PVCs of one StorageClass |
| `<class>.storageclass.storage.k8s.io/persistentvolumeclaims` | The number of PVCs of one StorageClass |
| `requests.ephemeral-storage` and `limits.ephemeral-storage` | The temporary disk space that containers request or are limited to |

The per-class keys let a team use a small amount of an expensive class, such as a class named `fast`, and a large amount of a cheap one, with one quota. The quota reads the class from the PVC's `storageClassName`.

## Create a storage quota

Save this as `quota-storage-budget.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-budget
  namespace: starfleet
spec:
  hard:
    requests.storage: 3Gi
    persistentvolumeclaims: "2"
```

Apply it:

```sh
kubectl apply -f quota-storage-budget.yaml
```

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

The PVC is admitted. In a `kind` cluster the default StorageClass waits for a pod to use the claim, so the PVC can stay `Pending`. The quota counts it from the moment the API server stores it, whether or not it is bound. Now request 2Gi more. Save this as `pvc-archive.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
```

Apply it:

```sh
kubectl apply -f pvc-archive.yaml
```

The API server rejects it with `exceeded quota: storage-budget` and names `requests.storage`: the claim asks for 2Gi, 2Gi is already used and the limit is 3Gi. Change the `storage` value in `pvc-archive.yaml` to `1Gi` and apply it again. It is admitted, and the quota now shows 3Gi of 3Gi and 2 of 2 claims. A third claim of any size would fail on `persistentvolumeclaims`, even with free storage.

Clean up:

```sh
kubectl -n starfleet delete pvc logbook archive
kubectl -n starfleet delete configmap crew-roster crew-shifts
kubectl -n starfleet delete quota object-budget storage-budget
```

You now know the object count and storage keys, that a count quota rejects the object over the limit, and that a PVC counts while it is still unbound. The remaining question is how to limit only some pods, such as pods that have no requests or pods that have a deadline.

## Common pitfalls

> [!WARNING]
> - **Writing the wrong key for a resource.** A Deployment is `count/deployments.apps`, not `count/deployments`. Check the API group with `kubectl api-resources` before you write the key.
> - **Forgetting objects you did not create.** The `kube-root-ca.crt` ConfigMap and objects made by controllers count too. Read `Used` before you choose a hard value.
> - **Assuming a PVC counts only when bound.** A `Pending` claim already uses quota.
