# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab has not been run on a live cluster; the text says what you will see instead of showing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS029.git -c sections/section-060/module-03/labs/lab-01
```

## Step 1: Read the current Deployment

Print the container section of the Deployment:

```sh
kubectl -n starfleet get deployment probe -o yaml
```

The `env` list has `DB_PASSWORD` with a plain `value`. Both Secrets exist in the same namespace, so the pod can reference them. Save the Deployment to a file to edit it:

```sh
kubectl -n starfleet get deployment probe -o yaml > deployment-probe.yaml
```

## Step 2: Use the Secret for DB_PASSWORD and mount the certificate

Edit `deployment-probe.yaml`. In the container, replace the `value` of `DB_PASSWORD` with a `valueFrom` block, add a `volumeMounts` list to the container, and add a `volumes` list to the pod spec:

```yaml
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: probe-credentials
                  key: password
          volumeMounts:
            - name: certificate
              mountPath: /etc/probe/tls
              readOnly: true
      volumes:
        - name: certificate
          secret:
            secretName: probe-certificate
            defaultMode: 0400
```

The environment variable can have only one source, so delete the `value: Plain-3030` line. Apply the file and wait for the rollout:

```sh
kubectl apply -f deployment-probe.yaml
kubectl -n starfleet rollout status deployment/probe
```

Check the result inside the pod:

```sh
kubectl -n starfleet exec deploy/probe -- printenv DB_PASSWORD
kubectl -n starfleet exec deploy/probe -- stat -L -c '%a %n' /etc/probe/tls/tls.key /etc/probe/tls/tls.crt
```

The first command prints the password from the Secret. The second prints the mode `400` and the path for both files. Submit the first two checks:

```sh
astrona submit --keep
```

If the apply fails with an error about a field that has both `value` and `valueFrom`, the plain value is still in the file. If the pod stays in `CreateContainerConfigError`, check the Secret and key names with `kubectl describe pod`.

## Step 3: Give the auditor one Secret

Save this as `role-probe-credentials-reader.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: probe-credentials-reader
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["probe-credentials"]
    verbs: ["get"]
```

Apply it and bind it:

```sh
kubectl apply -f role-probe-credentials-reader.yaml
kubectl -n starfleet create rolebinding auditor-reads-probe-credentials \
  --role=probe-credentials-reader --serviceaccount=starfleet:auditor
```

Then check the result:

```sh
kubectl -n starfleet auth can-i get secret/probe-credentials --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i get secret/probe-certificate --as=system:serviceaccount:starfleet:auditor
kubectl -n starfleet auth can-i list secrets --as=system:serviceaccount:starfleet:auditor
```

The first command prints `yes`, and the other two print `no`. Submit the final result:

```sh
astrona submit
```

All four checks pass. Clean up with `astrona destroy ats-029-lab-060-03`.
