# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED: the commands below follow documented Kubernetes behaviour, and no output is shown.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-03/labs/lab-01
```

## Step 1: Find the rejection

The Deployment is accepted, so the error is not on the Deployment. Look at the ReplicaSet events:

```sh
kubectl -n outpost get deployment bridge
kubectl -n outpost get events --field-selector reason=FailedCreate
```

The Deployment shows `0/1`, and the `FailedCreate` event says the pod violates PodSecurity `restricted:latest`. The message lists the failed checks: host namespaces (`hostNetwork=true`), `hostPath` volumes, `allowPrivilegeEscalation`, capabilities, `runAsNonRoot` and `seccompProfile`. Each item names a field to change.

## Step 2: Fix the pod template

Replace the pod template with a corrected one. Save this as `deployment-bridge-fixed.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bridge
  namespace: outpost
  labels:
    app: bridge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bridge
  template:
    metadata:
      labels:
        app: bridge
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      volumes:
        - name: work
          emptyDir: {}
        - name: tmp
          emptyDir: {}
      containers:
        - name: bridge
          image: docker.io/library/busybox:1.37.0
          command: ["sh", "-c", "echo up > /tmp/state; while true; do date > /work/heartbeat; sleep 5; done"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: work
              mountPath: /work
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 32Mi
```

Apply it:

```sh
kubectl apply -f deployment-bridge-fixed.yaml
```

The apply removes `hostNetwork` and the `hostPath` volume, because they are no longer in the file and the Deployment was created with `kubectl apply`. If the apply reports a conflict, run `kubectl -n outpost edit deployment bridge` and remove `hostNetwork` and the `hostPath` volume by hand. Wait for the rollout:

```sh
kubectl -n outpost rollout status deployment/bridge --timeout=120s
```

The command ends with a line that says the Deployment was successfully rolled out. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-03/labs/lab-01 --keep
```

All five checks should pass. If `writable-paths` fails, read the message: it says whether the heartbeat file or `/tmp/state` is missing.

## Step 3: Verify by hand

Test the read-only root filesystem, the writable volume and the user:

```sh
kubectl -n outpost exec deploy/bridge -- touch /rootfs-check
kubectl -n outpost exec deploy/bridge -- cat /tmp/state
kubectl -n outpost exec deploy/bridge -- id -u
kubectl -n outpost exec deploy/bridge -- grep '^Seccomp:' /proc/1/status
```

The first command fails with `Read-only file system`. The second prints `up`, the third prints `1000`, and the seccomp line shows `2`. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-03/labs/lab-01
```

Then remove the lab:

```sh
astrona destroy ats-029-lab-080-03
```
