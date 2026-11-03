# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster; the text says what you will see instead of showing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/capstone/labs/lab-01
```

## Step 1: Rotate the password and create the registry Secret

Patch only the `password` key. A patch with `stringData` changes the listed keys and keeps the others, so the `username` stays:

```sh
kubectl -n starfleet patch secret bridge-credentials -p '{"stringData":{"password":"Pulsar-2026"}}'
```

Create the registry Secret:

```sh
kubectl -n starfleet create secret docker-registry bridge-registry \
  --docker-server=registry.starfleet.example \
  --docker-username=fleet-puller \
  --docker-password='Warp-9000'
```

Check the keys and the type without printing values:

```sh
kubectl -n starfleet describe secret bridge-credentials
kubectl -n starfleet get secret bridge-registry -o jsonpath='{.type}{"\n"}'
```

The first Secret lists `password` and `username`. The type of the second is `kubernetes.io/dockerconfigjson`. The running `bridge` pod still has the old password in its environment, because a changed Secret never reaches a running container as a variable. Step 2 restarts it.

## Step 2: Change the Deployment

Save the current Deployment to a file:

```sh
kubectl -n starfleet get deployment bridge -o yaml > deployment-bridge.yaml
```

Edit `deployment-bridge.yaml` in three places. In the pod spec, add `imagePullSecrets` at the same level as `containers`. In the container, replace the plain `value` with a `secretKeyRef`, and add a `volumeMounts` list. In the pod spec, add a `volumes` list that mounts only the `password` key:

```yaml
      imagePullSecrets:
        - name: bridge-registry
      containers:
        - name: bridge
          env:
            - name: BRIDGE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: bridge-credentials
                  key: password
          volumeMounts:
            - name: credentials
              mountPath: /etc/bridge/credentials
              readOnly: true
      volumes:
        - name: credentials
          secret:
            secretName: bridge-credentials
            defaultMode: 0400
            items:
              - key: password
                path: password
```

Keep the other fields of the file as they are, and delete the line `value: Old-1000`. Apply the file. Changing the pod template starts a rollout, and the new pod starts with the rotated password:

```sh
kubectl apply -f deployment-bridge.yaml
kubectl -n starfleet rollout status deployment/bridge
```

Check the result inside the pod:

```sh
kubectl -n starfleet exec deploy/bridge -- printenv BRIDGE_PASSWORD
kubectl -n starfleet exec deploy/bridge -- ls /etc/bridge/credentials
kubectl -n starfleet exec deploy/bridge -- stat -L -c '%a %n' /etc/bridge/credentials/password
kubectl -n starfleet get pod -l app=bridge -o jsonpath='{.items[0].spec.imagePullSecrets}{"\n"}'
```

The variable holds `Pulsar-2026`. The directory lists only `password`, the mode is `400`, and the pod lists `bridge-registry`. Submit the first four checks:

```sh
astrona submit --keep
```

If the variable still holds the old password, the pod did not restart after the rotation. Run `kubectl -n starfleet rollout restart deployment/bridge`.

## Step 3: Give the auditor one Secret

Save this as `role-bridge-credentials-reader.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: bridge-credentials-reader
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["bridge-credentials"]
    verbs: ["get"]
```

Apply it and bind it:

```sh
kubectl apply -f role-bridge-credentials-reader.yaml
kubectl -n starfleet create rolebinding auditor-reads-bridge-credentials \
  --role=bridge-credentials-reader --serviceaccount=starfleet:auditor
```

Then check the result:

```sh
kubectl -n starfleet auth can-i get secret/bridge-credentials --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i list secrets --as=system:serviceaccount:starfleet:auditor
```

The first command prints `yes` and the second prints `no`. Submit the final result:

```sh
astrona submit
```

All five checks pass. Clean up with `astrona destroy ats-029-capstone-060`.
