# Lagoon Remote Controller

This chart installs the [Lagoon Remote Controller](https://github.com/uselagoon/remote-controller).

## Configuration

See the comments in `values.yaml`, and the [Lagoon Remote Controller](https://github.com/uselagoon/remote-controller) repository.

## Install

For simple use of Lagoon, you shouldn't install this chart directly.
Instead it is configured as a dependency of the [Lagoon Remote](https://github.com/uselagoon/lagoon-charts/tree/main/charts/lagoon-remote) chart.

## Custom Resource Definitions (CRDs)

When additions or changes are made to the CRDs, you will need to install the changes before installing the newer chart version. 

### lagoon-remote

If you're installing `lagoon-remote` you can use the following to update or install the latest CRDs

```
helm show crds lagoon/lagoon-build-deploy --version \
    $(curl -s "https://raw.githubusercontent.com/uselagoon/lagoon-charts/lagoon-remote-${LAGOON_REMOTE_CHART_VERSION}/charts/lagoon-remote/Chart.lock" \
    | grep -A2 "lagoon-build-deploy" \
    | grep "version" \
    | awk '{print $2}')
```
### lagoon-build-deploy

If you're installing `lagoon-build-deploy` as its own component, then the following can be used

```
helm show crds lagoon/lagoon-build-deploy --version ${LAGOON_BUILD_DEPLOY_CHART_VERSION}
```

## ServiceAccounts

This chart installs a single service account with a `cluster-admin` `ClusterRoleBinding`.
