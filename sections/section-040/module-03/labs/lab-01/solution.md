# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster yet, so the walkthrough describes results in words where the exact text is not certain.

Start the lab if it is not running:

```sh
astrona run -c sections/section-040/module-03/labs/lab-01
```

## Step 1: Look at the Deployment and the ConfigMap

Read the current container and the keys you can use:

```sh
kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].env}'
kubectl -n starfleet get configmap probe-settings -o jsonpath='{.data}'
```

The first command shows `LOG_LEVEL` with the fixed value `warn`. The second shows the keys `LOG_LEVEL`, `REGION` and `probe.properties`. The key `probe.properties` has a dot, so it cannot become an environment variable. With `envFrom` the kubelet skips it, and the pod still starts.

## Step 2: Edit the Deployment

You can change everything in one edit, which also means one rollout. Open the Deployment:

```sh
kubectl -n starfleet edit deployment probe
```

In the `probe` container, replace the `env` entry with this, which removes the `value` line completely:

```yaml
          env:
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: probe-settings
                  key: LOG_LEVEL
```

Add `envFrom` and `volumeMounts` to the same container, at the same indentation as `env`:

```yaml
          envFrom:
            - prefix: SETTING_
              configMapRef:
                name: probe-settings
          volumeMounts:
            - name: settings
              mountPath: /etc/probe
              readOnly: true
```

Add the volume under `spec.template.spec`, at the same indentation as `containers`:

```yaml
      volumes:
        - name: settings
          configMap:
            name: probe-settings
            items:
              - key: probe.properties
                path: probe.conf
                mode: 0444
```

Save and close the editor. The API server rejects a container that has both `value` and `valueFrom` on one variable, so remove the old `value` line. The `prefix` field is a sibling of `configMapRef`, not a child.

## Step 3: Wait for the rollout and check the pods

The edit changed the pod template, so the Deployment controller starts a rollout by itself. Wait for it:

```sh
kubectl -n starfleet rollout status deployment/probe
```

The command ends with `deployment "probe" successfully rolled out`. Check one pod:

```sh
kubectl -n starfleet exec deploy/probe -- printenv LOG_LEVEL
kubectl -n starfleet exec deploy/probe -- printenv SETTING_REGION
kubectl -n starfleet exec deploy/probe -- ls /etc/probe
kubectl -n starfleet exec deploy/probe -- stat -L -c '%a' /etc/probe/probe.conf
```

The commands print `debug`, `outpost-7`, `probe.conf` and `444`. Grade the lab:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

All five checks pass.

## Why the plausible wrong answers fail

Leaving the fixed `value: warn` fails step 1 and the rollout check, because the pods print `warn`. Writing the right fixed value `debug` by hand passes the value but fails the key reference check, because the point of the task is to follow the ConfigMap. Mounting the whole ConfigMap puts three files in `/etc/probe`, and `subPath` fails the mount check and would never receive updates. A mode written as `444` without the leading zero is a different number, and the pods report the wrong permissions. Editing the ConfigMap to fit the Deployment fails the last check. If the pods stay in `ContainerCreating` or `CreateContainerConfigError`, run `kubectl -n starfleet describe pod` on one of them and read the events: they name the key or the ConfigMap that cannot be found.
