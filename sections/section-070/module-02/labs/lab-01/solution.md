# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run end to end yet, so the output is described in words.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-02/labs/lab-01
```

## Step 1: Look at the starting state

Read the account and the volumes of the `scout` and `probe` pods:

```sh
kubectl -n starfleet get pods -l 'app in (scout,probe)' -o custom-columns=NAME:.metadata.name,ACCOUNT:.spec.serviceAccountName
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].spec.volumes[*].name}{"\n"}'
```

Both Deployments use `default`, and the `scout` pod has one volume whose name starts with `kube-api-access-`. That volume holds the token you must remove.

## Step 2: Create the scout account without a token mount

The field must be on the account. Save this as `serviceaccount-scout.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scout
  namespace: starfleet
automountServiceAccountToken: false
```

Apply it:

```sh
kubectl apply -f serviceaccount-scout.yaml
```

Then check the account:

```sh
kubectl -n starfleet get serviceaccount scout -o jsonpath='{.automountServiceAccountToken}{"\n"}'
```

You should see `false`. The check `scout-account-no-token` passes now. Do not touch the `default` account: a change there also reaches `shuttle`, which the task forbids.

## Step 3: Make the scout Deployment use the account

An existing pod cannot change its account, so change the Deployment and let it roll:

```sh
kubectl -n starfleet set serviceaccount deployment scout scout
kubectl -n starfleet rollout status deployment scout
kubectl -n starfleet get pods -l app=scout -o custom-columns=NAME:.metadata.name,ACCOUNT:.spec.serviceAccountName
kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].spec.volumes[*].name}{"\n"}'
```

The new pod shows `scout` as its account and the last command prints an empty line, because the pod has no volumes. Submit to see the progress:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-02/labs/lab-01 --keep
```

The checks `scout-account-no-token`, `scout-pods-no-token` and `scout-still-serves` pass. If `scout-pods-no-token` fails, the old pod may still be running: wait for the rollout to finish.

## Step 4: Create the probe account with the pull secret

Save this as `serviceaccount-probe.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: probe
  namespace: starfleet
imagePullSecrets:
  - name: regcred
```

Apply it, then make the Deployment use the account:

```sh
kubectl apply -f serviceaccount-probe.yaml
kubectl -n starfleet set serviceaccount deployment probe probe
kubectl -n starfleet rollout status deployment probe
```

The admission controller copies the account's `imagePullSecrets` into every new pod, so the pod created by the rollout has `regcred`. Check it, and check that the token volume is still there:

```sh
kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].spec.imagePullSecrets}{"\n"}'
kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].spec.volumes[*].name}{"\n"}'
```

The first command shows `regcred` and the second shows a `kube-api-access-` volume. If you roll the Deployment before you apply the account, the new pods have no pull secret: apply the account first and roll again.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-070/module-02/labs/lab-01
```

All five checks must pass. Then remove the lab:

```sh
astrona destroy ats-029-lab-070-02
```
