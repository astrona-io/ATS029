# Create A Custom Resource And Observe Its Controller Playground

Ungraded module environment: ats-029-playground-010-01. Kubernetes v1.35.0 is pinned by node image digest. Application tags identify versions but are not content-digest guarantees. Bootstrap only writes to the expected isolated context. No validation or grading block is registered in config.yaml.

```sh
astrona validate -c .
astrona run -c .
astrona destroy ats-029-playground-010-01
```

The [environment guide](docs/overview.md) describes fixtures and access. The author smoke script replays the practical reading from a temporary working directory and checks its outcome. It must run only after the playground starts and with its private kubeconfig. Runtime evidence is pending until an author executes it on a working container engine.

```sh
KUBECONFIG="$(astrona kubeconfig ats-029-playground-010-01)" bash testing/smoke.sh
```

The script is an author check, not a graded learner task. It uses live API and application observations and destroys no unrelated cluster. Destroy the environment after the check.
