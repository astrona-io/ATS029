# Summary

Every pod runs as exactly one ServiceAccount, a namespaced object that holds the identity of the workload. When a pod template names no account, the ServiceAccount admission controller in the API server writes `default` into the pod. The account must exist in the pod's own namespace when the pod is created, and it cannot be changed on a running pod.

You create an account with `kubectl create serviceaccount` or with YAML, and you assign it through `spec.template.spec.serviceAccountName` or with `kubectl set serviceaccount`. Changing a Deployment's account starts a rolling update. If the named account does not exist, the Deployment is accepted, the ReplicaSet records `FailedCreate` events, and the old pods keep running.

An account decides which credentials a pod receives at creation. By default the admission controller mounts a projected volume with a token, the cluster certificate authority file and the namespace name. The field `automountServiceAccountToken` switches that mount off. It can be set on the account or on the pod, and the pod value wins. The field removes the token from the pod; it does not remove permissions from the account.

A ServiceAccount can also list `imagePullSecrets`. The admission controller copies the list into every new pod that uses the account, so the kubelet can pull images from a private registry without a list in each pod template. The key facts to remember are these:

- A new account has no token Secret, no permissions and no pull secrets.
- The volume and the pull secrets are added when the pod is created, so running pods need a rollout.
- A missing account is reported on the ReplicaSet events, not on the Deployment command.
- Use a separate account for each workload that needs different credentials.

<!-- astrona:playground:destroy -->
