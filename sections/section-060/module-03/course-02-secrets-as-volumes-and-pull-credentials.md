---
draft: true
exam_objectives:
- Create & consume Secrets
---
# Secrets As Volumes And Pull Credentials

Some values do not fit well in an environment variable: a private key with many lines, a certificate bundle, or a password that changes often. Kubernetes can mount a Secret into the container as a directory of files. This part shows how to mount a Secret, how to choose which keys appear and with which permissions, how a mounted Secret updates, how to combine sources in one projected volume, and how a pod gets a registry login through `imagePullSecrets`.

## Mount a Secret as files

A **volume** is a directory that Kubernetes makes available to the containers of a pod. A pod declares volumes under `spec.volumes`, and each container chooses where to mount them under `volumeMounts`. A volume of the kind `secret` fills the directory with one file for each key of the Secret. The file name is the key, and the file content is the decoded value, with no base64 and no newline added.

The kubelet writes these files to an in-memory file system (`tmpfs`) on the node, so the Secret data is not written to the disk of the node. When the pod is deleted, the kubelet removes the files.

Save this as `deployment-shuttle.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shuttle
  namespace: starfleet
  labels:
    app: shuttle
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shuttle
  template:
    metadata:
      labels:
        app: shuttle
    spec:
      terminationGracePeriodSeconds: 1
      imagePullSecrets:
        - name: bridge-registry
      containers:
        - name: shuttle
          image: busybox:1.37.0
          command: ["sh", "-c", "sleep 3600"]
          volumeMounts:
            - name: credentials
              mountPath: /etc/shuttle/credentials
              readOnly: true
            - name: certificate
              mountPath: /etc/shuttle/certificate
              readOnly: true
            - name: bundle
              mountPath: /etc/shuttle/bundle
              readOnly: true
      volumes:
        - name: credentials
          secret:
            secretName: bridge-credentials
            defaultMode: 0400
        - name: certificate
          secret:
            secretName: bridge-certificate
            items:
              - key: tls.crt
                path: server.crt
                mode: 0444
        - name: bundle
          projected:
            sources:
              - secret:
                  name: bridge-credentials
                  items:
                    - key: username
                      path: account/username
              - secret:
                  name: bridge-certificate
                  items:
                    - key: tls.crt
                      path: account/server.crt
```

Apply it:

```sh
kubectl apply -f deployment-shuttle.yaml
```

Then check the files:

```sh
kubectl -n starfleet rollout status deployment/shuttle
kubectl -n starfleet exec deploy/shuttle -- ls /etc/shuttle/credentials
kubectl -n starfleet exec deploy/shuttle -- ls /etc/shuttle/certificate
kubectl -n starfleet exec deploy/shuttle -- stat -L -c '%a %n' /etc/shuttle/credentials/password
```

The `credentials` directory has two files, `password` and `username`. The `certificate` directory has only `server.crt`. The last command prints the permission mode and the path of the password file.

## Choose keys, names and permissions

The three volumes in the file use three different options. This section explains each.

By default, every key becomes a file. The `items` list changes that. Only the keys in `items` are mounted, and each item can give the file a different `path` inside the volume. In the `certificate` volume, only `tls.crt` is mounted, as `server.crt`. The key `tls.key` is not in the container at all. Listing only the keys a container needs is the least-privilege choice. If an item names a key that is not in the Secret, the pod does not start, unless the volume sets `optional: true`.

The file permissions come from `defaultMode` and from the `mode` of an item. The mode is an octal number, so write it with a leading zero in YAML, for example `0400`. The default is `0644`, which lets every user in the container read the file. With `defaultMode: 0400`, only the owner can read the file, and nobody can write it. A `mode` on an item overrides `defaultMode` for that file only. JSON files, and some tools that print the object as JSON, show the same number in decimal, so `0400` appears as `256`. The files belong to the root user, so a container that runs as another user may not be able to read a `0400` file. In that case choose a mode such as `0444`, or run the container as the user that owns the files.

The `readOnly: true` field in `volumeMounts` states that the container never writes to the directory. Kubernetes mounts Secret volumes read-only anyway, so the field documents the intention and keeps the manifest correct if the volume type changes.

## How a mounted Secret updates

Unlike environment variables, mounted files can change while the container runs. The kubelet checks the Secret periodically. When the Secret changes, the kubelet writes the new files to a new directory and then switches a symbolic link, so a reader never sees half of an update. The files you see in the mount point are links into a hidden directory named `..data`.

The update is not instant. It takes as long as the sync period of the kubelet plus the time its cache keeps old data, which is often a minute or longer. Test it:

```sh
kubectl -n starfleet patch secret bridge-credentials -p '{"stringData":{"password":"Comet-5150"}}'
kubectl -n starfleet exec deploy/shuttle -- cat /etc/shuttle/credentials/password
```

The first read may still show the old value. Run the second command again after a minute, and it shows `Comet-5150`, without a pod restart. The application must read the file again to use the new value. A program that reads the file only at startup keeps the old password in memory.

Three cases never update. A volume mounted with `subPath` is a copy of one file taken at start, so it does not follow later changes. An environment variable that came from the same Secret does not change. A Secret with `immutable: true` is not watched, so there is nothing to update. Because the update is delayed, a rotation must keep the old password valid until every pod shows the new file.

## Projected volumes

A **projected volume** puts several sources in one directory. The sources can be Secrets, ConfigMaps, the downward API (pod fields written as files) and ServiceAccount tokens. The `bundle` volume in the example combines one key from `bridge-credentials` and one from `bridge-certificate`:

```sh
kubectl -n starfleet exec deploy/shuttle -- ls /etc/shuttle/bundle/account
```

The directory has `username` and `server.crt`. Each source has its own `items`, and the file paths must not collide. Use a projected volume when an application expects one configuration directory but the data lives in several objects, with different owners and permissions.

## Image pull Secrets

When a node starts a pod, the container runtime must first download the image. If the image is in a private registry, the kubelet needs a login. It takes the login from a Secret of the type `kubernetes.io/dockerconfigjson`, which the pod names in `imagePullSecrets`. The list is in the pod spec, at the same level as `containers`, and the Secret must be in the same namespace as the pod.

The `shuttle` Deployment above already references `bridge-registry`. Check that the pod received the field:

```sh
kubectl -n starfleet get pod -l app=shuttle -o jsonpath='{.items[0].spec.imagePullSecrets}{"\n"}'
```

The output lists `bridge-registry`. The image of this pod is public, so the pull works with or without the Secret, and the Secret is simply present in the spec.

Adding the reference to every pod is tedious. You can attach it to the ServiceAccount, and every new pod that uses that ServiceAccount receives it. The ServiceAccount admission step of the API server copies the list into the pod when the pod is created:

```sh
kubectl -n starfleet patch serviceaccount probe -p '{"imagePullSecrets":[{"name":"bridge-registry"}]}'
kubectl -n starfleet rollout restart deployment/probe
kubectl -n starfleet rollout status deployment/probe
kubectl -n starfleet get pod -l app=probe -o jsonpath='{.items[0].spec.imagePullSecrets}{"\n"}'
```

Pods that already exist do not change, which is why the restart is needed. If the pull Secret is wrong or missing and the registry asks for a login, the pod shows the status `ErrImagePull` and then `ImagePullBackOff`. The events of the pod then show the registry error.

You now know how to mount, filter and protect Secret files, how updates reach a running container, and how a pod gets a registry login. The open question is who can read all these Secrets, and how well the cluster protects them.

## Common pitfalls

> [!WARNING]
> - **Using `0400` in a pod that runs as a non-root user.** The files belong to root, so the application gets permission denied. Check which user the container runs as, and choose the mode to match.
> - **Mounting with `subPath` and expecting updates.** A `subPath` mount never follows Secret changes.
> - **Reading the file once at startup.** The file updates, but the application keeps the old value in memory.
> - **A missing key in `items`.** The pod does not start. Check the key names with `kubectl describe secret`.
> - **Putting the pull Secret in another namespace.** It must be in the namespace of the pod.
