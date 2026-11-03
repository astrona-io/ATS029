---
draft: true
exam_objectives:
- Discover and use resources that extend Kubernetes (CRD, Operators)
---
# Summary

An extension of Kubernetes has two halves: a CustomResourceDefinition (CRD), which defines an API type, and an operator, which acts on objects of that type. The CRD makes the API server accept and validate the objects. The operator is an ordinary Deployment with a service account and a role, and it does the work.

## What you learned

You find the custom types of a cluster with the list of CRDs and with the API resources of a group, and you read their scope, versions and fields with `kubectl explain`. The API holds no link from a CRD to its operator. You find the operator through its Deployment, its labels, its service account and the role that names the API group.

An operator reconciles: it reads the desired state from the custom resource, compares it with the cluster, creates or patches the child objects, and writes the observed state into the status. The status holds `observedGeneration`, counts and a list of conditions with a type, a status, a reason and a message. The `metadata.generation` of an object rises with each change of the `spec`, so a status describes your latest change only when `observedGeneration` equals `metadata.generation`. The schema of the CRD rejects bad values before the operator sees them.

The operator marks its children with owner references. The garbage collector deletes dependents when their owner is gone, and the deletion option `orphan` keeps them without owner. A finalizer is a string in `metadata.finalizers` that keeps an object in the `Terminating` state until its owner removes it. An object stays stuck when the controller that owns the finalizer is missing, and removing the finalizer by hand skips the cleanup it stood for.

When a custom resource does not reconcile, you ask the same questions in order: is the type served, was the object accepted, does the operator run, may the operator act, does the status say why, and do the children exist. A stopped operator leaves an accepted object with no status and no children. A missing permission leaves a log line and a condition with the API server's refusal, and the fix is the exact missing verb in the role, never `cluster-admin`.

Key facts to remember:

- A CRD without a running operator accepts objects and does nothing with them.
- Compare the generation with the observed generation before you trust a condition.
- The garbage collector deletes the dependents of a deleted owner, not the operator.
- Check the permissions of an operator by impersonating its service account.
- Read the operator log, not only the custom resource.

<!-- astrona:playground:destroy -->
