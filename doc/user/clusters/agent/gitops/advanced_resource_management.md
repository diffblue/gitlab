---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Advanced Kubernetes resource management

There are special situations where the out-of-the-box resource ordering or configuration options are not good enough for a specific use case. The GitOps engine behind the GitLab agent for Kubernetes provides annotations in order to achieve:

- **Sorting**: adds optional resource sorting functionality to apply or delete objects in a particular order.
- **Apply Time Mutation**: adds optional functionality to dynamically substitute fields from one resource config into another.

While a [sane, default ordering](https://github.com/kubernetes-sigs/cli-utils/blob/d7d63f4b62897f584ca9e02b6faf4d2f327a9b09/pkg/ordering/sort.go#L74) is provided by the agent out of the box, annotations allow more fine-tuned ordering and even apply time value injection.

The GitLab agent for Kubernetes is based on the `cli-utils` library, a Kubernetes SIG project. You can read more about the `cli-utils` library and its advanced functions in [the project repository](https://github.com/kubernetes-sigs/cli-utils/). The following is based on the `cli-utils` documentation.

## Apply Sort Ordering

Adding an optional `config.kubernetes.io/depends-on: <OBJECT>` annotation to a
resource config provides apply ordering functionality. After manually specifying
the dependency relationship among applied resources with this annotation, the
library will sort the resources and apply/prune them in the correct order.
Importantly, the library will wait for an object to reconcile successfully within
the cluster before applying dependent resources. Prune (deletion) ordering is
the opposite of apply ordering.

In the following example, the `config.kubernetes.io/depends-on` annotation
identifies that `pod-c` must be successfully applied prior to `pod-a`
actuation:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-a
  annotations:
    config.kubernetes.io/depends-on: /namespaces/default/Pod/pod-c
spec:
  containers:
    - name: kubernetes-pause
      image: k8s.gcr.io/pause:2.0
```

## Apply-Time Mutation

**apply-time mutation** functionality allows library users to dynamically fill in
resource field values from one object into another, even though they are applied
at the same time. By adding a `config.kubernetes.io/apply-time-mutation` annotation,
a resource specifies the field in another object as well as the location for the
local field subsitution. For example, if an object's IP address is set during
actuation, another object applied at the same time can reference that IP address.
This functionality leverages the previously described **Apply Sort Ordering** to
ensure the source resource field is populated before applying the target resource.

In the following example, `pod-a` will substitute the IP address/port from the
source `pod-b` into the `pod-a` SERVICE_HOST environment variable:

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: pod-a
  annotations:
    config.kubernetes.io/apply-time-mutation: |
      - sourceRef:
          kind: Pod
          name: pod-b
        sourcePath: $.status.podIP
        targetPath: $.spec.containers[?(@.name=="nginx")].env[?(@.name=="SERVICE_HOST")].value
        token: ${pob-b-ip}
      - sourceRef:
          kind: Pod
          name: pod-b
        sourcePath: $.spec.containers[?(@.name=="nginx")].ports[?(@.name=="tcp")].containerPort
        targetPath: $.spec.containers[?(@.name=="nginx")].env[?(@.name=="SERVICE_HOST")].value
        token: ${pob-b-port}
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - name: tcp
      containerPort: 80
    env:
    - name: SERVICE_HOST
      value: "${pob-b-ip}:${pob-b-port}"
```
