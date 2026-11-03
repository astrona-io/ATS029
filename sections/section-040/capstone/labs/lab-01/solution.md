# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster yet, so the walkthrough describes results in words where the exact text is not certain.

Start the lab if it is not running:

```sh
astrona run -c sections/section-040/capstone/labs/lab-01
```

## Step 1: Create the two immutable ConfigMaps

The command `kubectl create configmap` has no flag for `immutable`, so write the objects as YAML. Both versions can go in one file. Save this as `configmaps-scout.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-config-v1
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: info
  REGION: outpost-7
  scout.conf: |
    interval=10
    timeout=2
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-config-v2
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: debug
  REGION: outpost-7
  scout.conf: |
    interval=10
    timeout=2
```

Apply it:

```sh
kubectl apply -f configmaps-scout.yaml
```

Then check that the API server refuses a change to the locked object. The server-side dry run stores nothing:

```sh
kubectl -n starfleet patch configmap scout-config-v1 --dry-run=server -p '{"data":{"LOG_LEVEL":"debug"}}'
```

The command fails with an error that says the `data` field is immutable. Grade the first two checks:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01 --keep
```

The check `versioned-immutable-configmaps` passes. The other checks still fail.

## Step 2: Wire scout-config-v2 into the Deployment

Open the Deployment:

```sh
kubectl -n starfleet edit deployment scout
```

In the `scout` container, add these three blocks at the same indentation as `image`:

```yaml
          env:
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: scout-config-v2
                  key: LOG_LEVEL
          envFrom:
            - prefix: SCOUT_
              configMapRef:
                name: scout-config-v2
          volumeMounts:
            - name: config
              mountPath: /etc/scout
              readOnly: true
```

Add the volume under `spec.template.spec`, at the same indentation as `containers`:

```yaml
      volumes:
        - name: config
          configMap:
            name: scout-config-v2
            items:
              - key: scout.conf
                path: scout.conf
                mode: 0440
```

Save and close the editor. The pod template changed, so the Deployment controller starts a rollout by itself. The prefix goes next to `configMapRef`, and `mode` has a leading zero because it is an octal number.

## Step 3: Wait for the rollout and check a pod

```sh
kubectl -n starfleet rollout status deployment/scout
```

The command ends with `deployment "scout" successfully rolled out`. Check one pod:

```sh
kubectl -n starfleet exec deploy/scout -- printenv LOG_LEVEL
kubectl -n starfleet exec deploy/scout -- printenv SCOUT_REGION
kubectl -n starfleet exec deploy/scout -- ls /etc/scout
kubectl -n starfleet exec deploy/scout -- stat -L -c '%a' /etc/scout/scout.conf
```

The commands print `debug`, `outpost-7`, `scout.conf` and `440`. Grade the lab:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

All five checks pass.

## Why the plausible wrong answers fail

Editing `scout-config-v1` into `debug` is not possible once it is immutable, and creating it without `immutable: true` fails the first check. Pointing the Deployment at `scout-config-v1` leaves the pods on `info`, which fails the environment check. Mounting the whole ConfigMap puts three files in `/etc/scout`, and `subPath` fails the reference check and would never receive updates. A mode written as `440` without the leading zero gives different permissions. If a pod stays in `CreateContainerConfigError` or `ContainerCreating`, run `kubectl -n starfleet describe pod` on it: the events name the missing ConfigMap or key.
