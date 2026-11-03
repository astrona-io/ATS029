# Overview: ServiceAccount Tokens And API Access (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Request tokens, call the API from a pod, bind roles, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. The `jq` tool on your machine prints token payloads.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `scout` and `probe` (`podinfo`), `shuttle` (`curl`) and the Secret `regcred`. Every workload runs as the `default` ServiceAccount, which has no permissions to list pods |
  | `outpost` | The `drifter` client, running as `default` |

## Helpers

Paste these once in each new terminal. `decode_token` prints the payload (the claims) of a token read from standard input. `api_status` runs from inside the `shuttle` pod and prints only the HTTP status code of a request to the API server path you give it, using the mounted token and certificate authority file.

```sh
decode_token() {
  cut -d. -f2 | tr '_-' '/+' | awk '{s=$0; while (length(s)%4) s=s "="; print s}' | base64 -d | jq .
}
api_status() {
  kubectl -n starfleet exec deploy/shuttle -- sh -c "curl -s -o /dev/null -w '%{http_code}\n' --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H \"Authorization: Bearer \$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" https://kubernetes.default.svc.cluster.local$1"
}
```

Use them like this: `kubectl -n starfleet create token default | decode_token`, `api_status /api/v1/namespaces/starfleet/pods`.

## Practice tasks

- Request a token for `default` with `--duration=20m` and again with `--audience=probe`. Decode both and compare `aud` and the time claims.
- Run `api_status` for the pods path and the secrets path as `default`. Predict the code first.
- Create a ServiceAccount `shuttle`, a Role that allows `get` and `list` on pods, and a RoleBinding. Point the `shuttle` Deployment at the account and run `api_status` again.
- Use `kubectl auth can-i --as=system:serviceaccount:starfleet:shuttle` with several verbs and namespaces. Compare the answers with the real requests.
- Create a token Secret of type `kubernetes.io/service-account-token` and read its `token` key. Delete the Secret and see what happens to the token.
