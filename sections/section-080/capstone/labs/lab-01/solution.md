# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED: the commands below follow documented Kubernetes behaviour, and no output is shown.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/capstone/labs/lab-01
```

## Step 1: Find the rejection

The Deployment is accepted, so look at the events of its ReplicaSet:

```sh
kubectl -n starfleet get deployment probe
kubectl -n starfleet get events --field-selector reason=FailedCreate
```

The Deployment shows `0/1`. The `FailedCreate` event says the pod violates PodSecurity `restricted:latest` and lists the failed checks: host namespaces, privileged containers, `hostPath` volumes, `allowPrivilegeEscalation`, capabilities, `runAsNonRoot` and `seccompProfile`. The checks are the minimum. The task asks for more: the user and group, the volume group, a read-only root filesystem and a sysctl.

## Step 2: Write the corrected Deployment

The pod-level `securityContext` holds `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `seccompProfile` and `sysctls`. The container-level `securityContext` holds `allowPrivilegeEscalation`, `readOnlyRootFilesystem` and `capabilities`, and the `logger` override of `runAsUser`. Save this as `deployment-probe-fixed.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe
  namespace: starfleet
  labels:
    app: probe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: probe
  template:
    metadata:
      labels:
        app: probe
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 3000
        runAsGroup: 3000
        fsGroup: 4000
        seccompProfile:
          type: RuntimeDefault
        sysctls:
          - name: net.ipv4.ip_local_port_range
            value: "32768 40000"
      volumes:
        - name: shared
          emptyDir: {}
        - name: tmp
          emptyDir: {}
      containers:
        - name: probe
          image: docker.io/library/busybox:1.37.0
          command: ["sh", "-c", "echo up > /tmp/state; while true; do date > /shared/heartbeat; sleep 5; done"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: shared
              mountPath: /shared
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 32Mi
        - name: logger
          image: docker.io/library/busybox:1.37.0
          command: ["sh", "-c", "while true; do date > /shared/logger-seen; sleep 5; done"]
          securityContext:
            runAsUser: 3500
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: shared
              mountPath: /shared
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 32Mi
```

Apply it and wait for the rollout:

```sh
kubectl apply -f deployment-probe-fixed.yaml
kubectl -n starfleet rollout status deployment/probe --timeout=120s
```

The command ends with a line that says the Deployment was successfully rolled out. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/capstone/labs/lab-01 --keep
```

All five checks should pass. Each failing check names the container and the value it found.

## Step 3: Verify by hand

Check the identity, the volume, the sysctl and the filesystem:

```sh
kubectl -n starfleet exec deploy/probe -c probe -- id -u
kubectl -n starfleet exec deploy/probe -c logger -- id -u
kubectl -n starfleet exec deploy/probe -c probe -- stat -c '%u:%g' /shared/heartbeat
kubectl -n starfleet exec deploy/probe -c probe -- cat /proc/sys/net/ipv4/ip_local_port_range
kubectl -n starfleet exec deploy/probe -c probe -- touch /rootfs-check
```

The user IDs are 3000 and 3500, the heartbeat file belongs to `3000:4000`, the port range is 32768 and 40000, and the last command fails with `Read-only file system`. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/capstone/labs/lab-01
```

Then remove the lab:

```sh
astrona destroy ats-029-capstone-080
```
