---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Secrets As Environment Variables

The simplest way to give an application a password is an environment variable, because almost every program can read one. Kubernetes fills the variables from a Secret when it starts the container, so the value never appears in the Deployment YAML. This part shows the two ways to do it, `secretKeyRef` for one key and `envFrom` for all keys, the error a wrong reference causes, and the rule that a running container never receives a changed value.

## Inject one key with secretKeyRef

An **environment variable** is a named value that a process receives from its parent when it starts. In a pod spec, each container has an `env` list. An entry with `value` sets a fixed string. An entry with `valueFrom` takes the value from another object. For a Secret, the field is `secretKeyRef`, and it names the Secret and one key in it.

The playground has a Secret `bridge-credentials` with the keys `username` and `password`. Save this as `deployment-scout.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: starfleet
  labels:
    app: scout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      serviceAccountName: scout
      terminationGracePeriodSeconds: 1
      containers:
        - name: scout
          image: busybox:1.37.0
          command: ["sh", "-c", "sleep 3600"]
          env:
            - name: BRIDGE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: bridge-credentials
                  key: password
```

Apply it:

```sh
kubectl apply -f deployment-scout.yaml
```

Then check what the container received:

```sh
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet exec deploy/scout -- printenv BRIDGE_PASSWORD
```

The command prints `Nebula-7421`. The kubelet (the agent on each node that starts containers) read the Secret from the API server, decoded the base64 value and put it in the environment of the container process. The name of the variable, `BRIDGE_PASSWORD`, does not have to match the key name `password`. You choose the variable name that the application expects.

Look at how the pod description shows the variable:

```sh
kubectl -n starfleet describe pod -l app=scout
```

In the container section, the variable appears as a reference to the key `password` in the Secret `bridge-credentials`. The description shows the reference and never the value. The value is visible only inside the container, for example with `printenv`.

## Inject all keys with envFrom

A Secret with many keys would need one `env` entry for each key. The `envFrom` list takes a whole Secret in one entry. Each key becomes a variable with the same name as the key. The optional `prefix` field puts text in front of every name, which avoids clashes when you use two Secrets.

Replace the `env` block of the container in `deployment-scout.yaml` with this block, and save the file again:

```yaml
          envFrom:
            - prefix: BRIDGE_
              secretRef:
                name: bridge-credentials
```

Apply it and look at the variables:

```sh
kubectl apply -f deployment-scout.yaml
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet exec deploy/scout -- printenv BRIDGE_username BRIDGE_password
```

The container now has `BRIDGE_username` and `BRIDGE_password`. Only keys that are valid variable names are injected. A key such as `tls.crt` contains a dot, which is not valid in many shells, so Kubernetes skips it and records a warning event on the pod. The rest of the keys still work.

If the same variable name appears in `env` and in `envFrom`, the `env` entry wins. If two `envFrom` entries set the same name, the later entry wins. Use a prefix so you never have to remember this order.

## The kubectl shortcut

On the exam you can add the variables without editing YAML. The `kubectl set env` command changes the pod template of a Deployment, which starts a new rollout:

```sh
kubectl -n starfleet set env deployment/probe --from=secret/bridge-credentials --prefix=PROBE_
```

The `--from` flag takes `secret/<name>` and adds every key as a variable. The `--prefix` flag adds the same prefix as in `envFrom`. Without the `--keys` flag, the command writes an `envFrom` entry with a `secretRef`. With `--keys=password`, it writes an `env` entry with a `secretKeyRef` for that key. Check the result with `kubectl -n starfleet get deployment probe -o yaml` and look at the container section.

## When the reference is wrong

A reference to a Secret or a key that does not exist stops the container from starting. The pod stays in the `CreateContainerConfigError` status, because the kubelet cannot build the container configuration. Test it by pointing a variable at a Secret that does not exist:

```sh
kubectl -n starfleet set env deployment/probe --from=secret/bridge-missing
kubectl -n starfleet get pods -l app=probe
kubectl -n starfleet describe pod -l app=probe
```

The new pod shows `CreateContainerConfigError`. The events section of the description says that the Secret `bridge-missing` was not found. A reference to an existing Secret with a wrong key gives a different message that says the key was not found in the Secret, and it names both. The old pod keeps running during the rollout, because the Deployment does not remove it until the new pod is ready.

Go back to the previous working revision of the Deployment before you continue:

```sh
kubectl -n starfleet rollout undo deployment/probe
```

Setting `optional: true` on the `secretKeyRef` or the `secretRef` changes this. The container then starts without the variable when the Secret or key is missing. Use it only when the application works without the value, because a silent missing password is harder to find than a pod that does not start.

## A running container keeps its value

The environment of a process is fixed when the process starts. Kubernetes does not change it afterward. Update the Secret and look again:

```sh
kubectl -n starfleet patch secret bridge-credentials -p '{"stringData":{"password":"Pulsar-2026"}}'
kubectl -n starfleet exec deploy/scout -- printenv BRIDGE_password
```

The Secret now holds the new password, but the container still prints the old one. The pods must restart so the kubelet builds a new environment:

```sh
kubectl -n starfleet rollout restart deployment/scout
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet exec deploy/scout -- printenv BRIDGE_password
```

After the restart, the new pod prints `Pulsar-2026`. A password rotation with environment variables therefore always has two steps: update the Secret, then roll the Deployment. If you skip the second step, the pods keep working with the old value until something else restarts them, and then they change without warning.

## Where environment variables leak

Environment variables are convenient and exposed in more places than files. Any process in the container can read them, including child processes the application starts. Many applications print their environment in a crash report or a debug log. The variables are also visible to anyone who can run `kubectl exec` in the pod. Use them for values the application reads once at startup, and prefer files for values that are long, binary or rotated often.

You now know how a Secret reaches a container as variables, what a wrong reference looks like, and why a rollout is the only way to deliver a changed value. The open question is how to deliver a Secret as files, which can update without a restart, and how the kubelet gets a registry login.

## Common pitfalls

> [!WARNING]
> - **Expecting a running pod to see a new Secret value.** Environment variables are fixed at start. Restart the pods.
> - **A wrong Secret name or key.** The pod stays in `CreateContainerConfigError`. Read the events with `kubectl describe pod`.
> - **Using `envFrom` with keys that are not valid variable names.** Kubernetes skips them and only records an event.
> - **Setting `optional: true` to silence an error.** The application then starts without its password.
> - **Printing the environment in logs.** The value goes to the log system, which many people can read.
