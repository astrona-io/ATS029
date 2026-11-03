# Summary

A ServiceAccount token is a signed JSON Web Token that identifies an account to the API server. The user name in it is `system:serviceaccount:<namespace>:<name>`. A pod normally receives a projected token: the kubelet requests it through the TokenRequest API, binds it to the pod, writes it to a file in the container and renews it before it expires. The default lifetime is about one hour, and a token stops working when its pod is deleted.

You can request a token with `kubectl create token`, with a chosen duration (at least 10 minutes) and a chosen audience. Nothing is stored in the cluster. The payload of a token is readable text, so a token must be treated like a password. A Secret of type `kubernetes.io/service-account-token` is the legacy way: it holds a token without an expiry time until the Secret or the account is deleted.

A pod calls the API server over HTTPS at `kubernetes.default.svc.cluster.local`. It trusts the server with the mounted `ca.crt` file and authenticates with the mounted token in an `Authorization: Bearer` header. Status `401` means authentication failed. Status `403` means the caller is known and no rule allows the request, and its message names the user, the verb, the resource and the namespace.

A new account has almost no permissions. A Role lists rules and a RoleBinding gives the Role to the account in one namespace. The command `kubectl auth can-i <verb> <resource> -n <namespace> --as=system:serviceaccount:<namespace>:<name>` tests the result without opening a pod. The key facts to remember are these:

- A token proves identity; a Role and a RoleBinding grant permission.
- `403` is fixed with a rule, and `401` is fixed with a valid token.
- A RoleBinding reaches only its own namespace, and the subject needs its namespace written out.
- A pod receives its new account only when it is created again.

<!-- astrona:playground:destroy -->
