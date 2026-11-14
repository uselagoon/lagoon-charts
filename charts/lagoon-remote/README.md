# Lagoon Remote

This chart installs the remote services for [Lagoon](https://github.com/uselagoon/lagoon/).
Install this chart into the cluster you want to deploy workloads to.

## Configuration

None.

After this chart is installed, Lagoon needs to be configured to deploy to this cluster.
This is outside the scope of this README.

## Install

*NOTE:* This chart must be installed into the `lagoon` namespace because software that consumes lagoon services inside the cluster assumes that services are available at `*.lagoon.svc`.

```
helm upgrade --install --create-namespace --namespace lagoon lagoon-remote ./charts/lagoon-remote
```

### docker-host

The docker-hosts are provisioned by the [docker-host-operator](https://github.com/uselagoon/docker-host-operator)
from the `LagoonDockerHost` resource defined in the `dockerHost` values. The chart installs the operator
(`dockerHostOperator`), the `LagoonDockerHost` CRD (in `crds/`) and the resource itself.

Helm does not upgrade CRDs in `crds/`, apply them manually when upgrading the operator:

```
kubectl apply -f charts/lagoon-remote/crds/
```

Upgrading from a chart version that deployed the docker-host as a StatefulSet replaces it with deployments that use
new volumes, so the docker image cache is rebuilt. The `docker-host` service is recreated by the operator.
Additional isolated docker-hosts can be defined with `dockerHost.additional`, keyed by the name of each
`LagoonDockerHost`. The main resource is named `dockerHost.name` (`docker-host`), which keeps the service name the
`remote-controller` falls back to.

#### Scaling

The chart sets the scaling bounds (`dockerHost.spec.minReplicas` and `maxReplicas`) but does not render
`spec.replicas`. When unset the pool runs `minReplicas` docker-hosts. The field is left to whatever scales the pool,
so a `helm upgrade` never reverts a scaling decision. The operator clamps the requested count to the bounds and reports
the effective count in `status.replicas`. Only set `dockerHost.spec.replicas` if nothing else scales the pool, as helm
then owns the field. The first upgrade after removing a rendered `replicas` resets the pool to `minReplicas` once.

Anything that scales the pool (for example the `remote-controller`) uses the `scale` subresource of the
`LagoonDockerHost` resource, and needs this RBAC in the namespace of the docker-hosts (or cluster wide):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lagoondockerhost-scaler
  namespace: lagoon
rules:
- apiGroups: ["crd.lagoon.sh"]
  resources: ["lagoondockerhosts"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["crd.lagoon.sh"]
  resources: ["lagoondockerhosts/scale"]
  verbs: ["get", "update", "patch"]
```

bound to the scaler's ServiceAccount with a `RoleBinding`. Without `lagoondockerhosts/scale` a scale request is
rejected with `403 Forbidden`. The `lagoon-build-deploy` subchart (`remote-controller`) is bound to `cluster-admin`
by default, so this is only needed if you have restricted its permissions. Do not grant `update` on
`lagoondockerhosts` itself, scalers should not be able to change the docker-host configuration.

## Uninstall

```
helm uninstall lagoon-remote
```

## ServiceAccounts

* The `kubernetesbuilddeploy` serviceaccount is bound to `cluster-admin`.

## NATS

This section only applies if using NATS for ssh-portal support.
NATS and ssh-portal are currently disabled by default.

### Configuring NATS

The minimum configuration required to enable NATS is:

```
nats:
  enabled: true
  cluster:
    name: lagoon-remote-example
```

Note that the cluster name used in Lagoon Core and each Lagoon Remote _must_ be unique in order for NATS routing to work correctly.

### Securing NATS

See the Lagoon Core chart README for instructions for securing NATS.
