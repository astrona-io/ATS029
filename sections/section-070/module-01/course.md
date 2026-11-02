---
draft: true
exam_objectives:
- Understand ServiceAccounts
---
# ServiceAccounts And Bound Workload Credentials

The `probe` application can run without reading Kubernetes resources, while a controller needs a workload identity to call the API. Giving both the same mounted credentials exposes authority where it may not be needed.

## Learning Goals

- Explain ServiceAccount identity and namespace scope.
- Distinguish credential delivery from permission grants.
- Evaluate token audience, expiry and workload use.
- Choose least-privilege access for an application role.

## Before You Start

Use the module playground for guided practice. It provides an isolated kind cluster and the declared starting fixtures. You need the Astrona command-line tool, kubectl and a working Podman engine; selected exercises also use Helm, curl or OpenSSL. Keep the module's private kubeconfig selected when running application commands.

## Reading Order

1. API Identity And ServiceAccounts
2. RBAC Scope And Least Privilege
3. Use A Workload ServiceAccount For A Real API Request
4. Summary

The playground provides the initial state for the guided practice. Keep it open while following the practical steps.

<!-- astrona:playground -->
