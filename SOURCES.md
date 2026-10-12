# Primary Authoring Sources

Objectives checked on 2026-10-11. CKAD is performance based. These references support author review; learner pages are self-contained. Mechanisms adapted from the KCNA and KCSA teaching are recorded per reading in AUTHORING.yaml. The CKAD-specific lessons add application definitions, lifecycle decisions and diagnostic reasoning. No runtime or command output is claimed.

- [Official CKAD domains and format](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/)
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/)
- [Dockerfile build concepts](https://docs.docker.com/build/concepts/dockerfile/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Sidecars](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
- [Volume lifecycle](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [API migration](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [Health probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/)
- [Resource allocation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [ServiceAccounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [Security contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Application diagnosis](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Helm package use](https://helm.sh/docs/intro/using_helm/)

Check version-specific fields and tool options against the intended platform before adding executable examples. YAML checks are original learning material, not an examination simulator.

## Playground Authoring Sources

Checked on 2026-10-12. The kind node image is pinned to a known practice release rather than asserted as the current examination version. Astrona runtime, addon and private-kubeconfig behavior was checked against the local astrona-cli source.

- [kind node release and digest](https://github.com/kubernetes-sigs/kind/releases)
- [Traefik Ingress provider](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik v3.6.1](https://github.com/traefik/traefik/releases/tag/v3.6.1)
- [podinfo chart release 6.7.1](https://github.com/stefanprodan/podinfo/releases/tag/6.7.1)
- [Kubernetes container images](https://kubernetes.io/docs/concepts/containers/images/)
- [Kubernetes Pod configuration](https://kubernetes.io/docs/tasks/configure-pod-container/)

Application images use explicit release or minor tags; those tags are not content-digest guarantees. Runtime pulls and live API observations must be verified on the target environment. No successful execution output is fabricated.

## Material expansion review — 2026-10-12

Applied the local astrona-course-expand-material skill with CLAUDE.md prose and lifecycle rules. Author references reviewed for image policy, sidecar lifecycle, volume access/reclaim, resource accounting, identity and request-path behavior:

- https://kubernetes.io/docs/concepts/containers/images/
- https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/
- https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
- https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://kubernetes.io/docs/concepts/services-networking/network-policies/
- https://helm.sh/docs/helm/helm_upgrade/
