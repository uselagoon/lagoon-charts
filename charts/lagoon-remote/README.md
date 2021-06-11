# Lagoon Remote

This chart installs the remote services for [Lagoon](https://github.com/amazeeio/lagoon/).
Install this chart into the cluster you want to deploy workloads to.

## Configuration

None.

After this chart is installed, Lagoon needs to be configured to deploy to this cluster.
This is outside the scope of this README.

## Install

*NOTE:* This chart must be installed into the `lagoon` namespace because software that consumes lagoon services inside the cluster asumes that services are available at `*.lagoon.svc`.

```
helm upgrade --install --create-namespace --namespace lagoon lagoon-remote ./charts/lagoon-remote
```

### OpenShift

the included docker-host needs `priviledged` permissions:

```
oc -n lagoon adm policy add-scc-to-user privileged  -z lagoon-remote-docker-host
```

## Uninstall

```
helm uninstall lagoon-remote
```

## ServiceAccounts

* The `kubernetesbuilddeploy` serviceaccount is bound to `cluster-admin`.
