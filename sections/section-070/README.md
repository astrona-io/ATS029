---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# Understand ServiceAccounts

This section covers the CKAD objective "Understand ServiceAccounts". Every pod runs as a ServiceAccount, and every request a pod sends to the Kubernetes API carries that identity. You will learn what the identity is, how to create and assign one, how its credentials reach the pod, and how to give it exactly the permissions its job needs.

Each module begins with its goals and ends with a summary. Each module has its own playground and one graded lab, and the section ends with a capstone lab and a knowledge check.

## Modules

1. **ServiceAccounts And Bound Workload Credentials.** The API request path, workload identity, projected tokens, and RBAC scope for a ServiceAccount.
2. **Create And Assign ServiceAccounts.** The `default` account, `kubectl create serviceaccount`, `serviceAccountName`, `kubectl set serviceaccount`, `automountServiceAccountToken` on the account and on the pod, and `imagePullSecrets` on an account.
3. **ServiceAccount Tokens And API Access.** Projected and requested tokens with `kubectl create token`, the legacy token Secret, calling the API from a pod with `curl`, a Role and a RoleBinding for a ServiceAccount, and `kubectl auth can-i --as`.

## Learning Outcomes

- Explain ServiceAccount identity and namespace scope.
- Distinguish credential delivery from permission grants.
- Evaluate token audience, expiry and workload use.
- Choose least-privilege access for an application role.
- Create a ServiceAccount and assign it to a pod or Deployment, and explain what happens when the named account is missing.
- Switch the token mount off on an account or a pod, and attach image pull secrets to an account.
- Request a token with a duration and an audience, and read its claims.
- Call the Kubernetes API from a pod, read a 401 or 403 response, and grant a ServiceAccount one permission with a Role and a RoleBinding.

Finish each module's practice and summary before moving on. The capstone lab combines all three modules in one task.
