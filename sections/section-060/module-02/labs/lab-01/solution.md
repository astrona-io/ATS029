# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster; the text says what you will see instead of showing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-02/labs/lab-01
```

## Step 1: See why scout does not start

List the pods and read the status of the `scout` pod:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet describe pod -l app=scout
```

The pod status is `CreateContainerConfigError`, and the events say that the Secret `scout-credentials` is not found. The kubelet cannot build the environment of the container without it. The Deployment is correct; the Secret is missing.

## Step 2: Create scout-credentials

Use `--from-literal` so that the value has no trailing newline:

```sh
kubectl -n starfleet create secret generic scout-credentials --from-literal=api-key=ion-4471
```

The kubelet retries on its own. Wait for the pod to become ready, then check what the container sees:

```sh
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet exec deploy/scout -- printenv API_KEY
```

The last command prints `ion-4471`. Submit the first check:

```sh
astrona submit --keep
```

## Step 3: Create bridge-settings from an environment file

Write the two lines to a file and create the Secret from it:

```sh
printf 'REGION=outpost-4\nTIER=gold\n' > bridge.env
kubectl -n starfleet create secret generic bridge-settings --from-env-file=bridge.env
rm -f bridge.env
```

Check the keys without printing the values:

```sh
kubectl -n starfleet describe secret bridge-settings
```

The data section lists `REGION` and `TIER`. If you used `--from-file`, you would see one key named `bridge.env` instead, and the check would fail.

## Step 4: Create bridge-registry

```sh
kubectl -n starfleet create secret docker-registry bridge-registry \
  --docker-server=registry.starfleet.example \
  --docker-username=fleet-puller \
  --docker-password='Warp-9000'
```

Check the type:

```sh
kubectl -n starfleet get secret bridge-registry -o jsonpath='{.type}{"\n"}'
```

The type is `kubernetes.io/dockerconfigjson`.

## Step 5: Make scout-credentials immutable

Patch the Secret now that its value is correct:

```sh
kubectl -n starfleet patch secret scout-credentials -p '{"immutable":true}'
kubectl -n starfleet patch secret scout-credentials --dry-run=server -p '{"stringData":{"api-key":"test"}}'
```

The second command is a server-side dry run, so it changes nothing. It fails with an error that says the field is immutable. Submit the final result:

```sh
astrona submit
```

All four checks pass. Clean up with `astrona destroy ats-029-lab-060-02`.
