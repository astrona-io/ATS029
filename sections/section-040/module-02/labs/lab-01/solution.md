# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster yet, so the walkthrough shows what each command must do and describes results in words where the exact text is not certain.

Start the lab if it is not running:

```sh
astrona run -c sections/section-040/module-02/labs/lab-01
```

## Step 1: Create scout-env from an environment file

The task asks for one key for each line, so the source flag is `--from-env-file`. The flag `--from-file` would store the whole file as a single key named after the file. Save this as `scout.env`:

```text
MODE=fast
RETRIES=3
```

Create the ConfigMap:

```sh
kubectl -n starfleet create configmap scout-env --from-env-file=scout.env
```

You should see:

```text
configmap/scout-env created
```

Check the keys:

```sh
kubectl -n starfleet get configmap scout-env -o jsonpath='{.data}'
```

The output is a JSON object with the two keys `MODE` and `RETRIES`. If you see a key called `scout.env`, you used `--from-file`: delete the ConfigMap with `kubectl -n starfleet delete configmap scout-env` and create it again.

## Step 2: Create scout-files with a chosen key

The file name on your machine does not matter, because `--from-file=KEY=PATH` sets the key. Save this as `scout.properties`:

```text
retries=3
region=outpost-7
```

Save this as `banner.txt`:

```text
scout online
```

Create the ConfigMap with both files, and choose the key `app.properties` for the first one:

```sh
kubectl -n starfleet create configmap scout-files --from-file=app.properties=scout.properties --from-file=banner.txt
```

Check the keys:

```sh
kubectl -n starfleet describe configmap scout-files
```

The output lists two keys, `app.properties` and `banner.txt`, with the file content under each one. Grade steps 1 and 2:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01 --keep
```

The checks `scout-env-has-one-key-per-line` and `scout-files-has-chosen-key` pass. The other two still fail.

## Step 3: Create the immutable ConfigMap

The command `kubectl create configmap` has no flag for `immutable`, so write the object as YAML. Save this as `configmap-scout-locked.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-locked
  namespace: starfleet
immutable: true
data:
  LOG_LEVEL: warn
```

Apply it:

```sh
kubectl apply -f configmap-scout-locked.yaml
```

Then check that the API server refuses a change. The server-side dry run stores nothing:

```sh
kubectl -n starfleet patch configmap scout-locked --dry-run=server -p '{"data":{"LOG_LEVEL":"debug"}}'
```

The command fails with an error that says the `data` field is immutable when `immutable` is set.

## Step 4: Change one key of probe-settings

The object must keep `probe.conf`, so change only one key. A patch does that:

```sh
kubectl -n starfleet patch configmap probe-settings -p '{"data":{"LOG_LEVEL":"info"}}'
```

You should see `configmap/probe-settings patched`. Check both keys:

```sh
kubectl -n starfleet get configmap probe-settings -o jsonpath='{.data}'
```

The output shows `LOG_LEVEL` with the value `info` and `probe.conf` with its two lines. Do not use `kubectl replace` with a file that holds only `LOG_LEVEL`: replace swaps the whole object, so `probe.conf` would disappear. Grade the whole lab:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

All four checks pass.

## Why the plausible wrong answers fail

Using `--from-file=scout.env` for step 1 creates one key named `scout.env`, so the key set is wrong. Using `--from-file=scout.properties` for step 2 creates the key `scout.properties`, which the application does not expect. Applying `scout-locked` without `immutable: true`, or with the field under `data`, leaves it editable. Replacing `probe-settings` with a partial file or recreating it without `probe.conf` fails the last check, and setting `immutable: true` on it fails the same check, because the team still needs to edit it.
