# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab is UNTESTED: the commands below follow documented Kubernetes behaviour, and no output is shown.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-02/labs/lab-01
```

## Step 1: Look at the current state

Read the pod template of the Deployment:

```sh
kubectl -n starfleet get deployment shuttle -o yaml
```

The `shuttle` container has `privileged: true`. The pod has no `securityContext`, and the volume `data` is an `emptyDir`. Check the identity that runs today:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- id
```

The user and the group are 0, which is root.

## Step 2: Set the identity and the volume group at pod level

The fields `runAsUser`, `runAsGroup` and `fsGroup` go in the pod-level `securityContext`. A strategic merge patch changes the pod template and keeps the rest of the Deployment:

```sh
kubectl -n starfleet patch deployment shuttle -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":1500,"runAsGroup":3000,"fsGroup":4000}}}}}'
```

You should see `deployment.apps/shuttle patched`.

## Step 3: Fix the privilege of each container

A strategic merge patch merges the container list by the key `name`. The value `null` removes a field, so `"privileged":null` removes the privileged mode. The `relay` container also gets its own `runAsUser`, which replaces the pod-level value for that container:

```sh
kubectl -n starfleet patch deployment shuttle -p '{"spec":{"template":{"spec":{"containers":[{"name":"shuttle","securityContext":{"privileged":null,"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}},{"name":"relay","securityContext":{"runAsUser":2500,"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
```

You should see `deployment.apps/shuttle patched`. Wait for the rollout:

```sh
kubectl -n starfleet rollout status deployment/shuttle
```

The command ends with a line that says the Deployment was successfully rolled out. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-02/labs/lab-01 --keep
```

All four checks should pass. If `no-privilege` fails, read the message: it names the container and the field. If `identity` fails, check that only `relay` has its own `runAsUser`.

## Step 4: Verify by hand

Check the identity in both containers, the owner of the volume and the capability mask:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- id -u
kubectl -n starfleet exec deploy/shuttle -c relay -- id -u
kubectl -n starfleet exec deploy/shuttle -c relay -- stat -c '%u:%g' /data/heartbeat
kubectl -n starfleet exec deploy/shuttle -c shuttle -- grep CapEff /proc/1/status
```

The user IDs are 1500 and 2500, the heartbeat file belongs to `1500:4000`, and the capability mask is all zeros. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-080/module-02/labs/lab-01
```

Then remove the lab:

```sh
astrona destroy ats-029-lab-080-02
```
