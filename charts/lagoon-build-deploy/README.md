# Lagoon Remote Controller

This chart installs the [Lagoon Remote Controller](https://github.com/uselagoon/remote-controller).

## Configuration

See the comments in `values.yaml`, and the [Lagoon Remote Controller](https://github.com/uselagoon/remote-controller) repository.

## Install

For simple use of Lagoon, you shouldn't install this chart directly.
Instead it is configured as a dependency of the [Lagoon Remote](https://github.com/uselagoon/lagoon-charts/tree/main/charts/lagoon-remote) chart.

## ServiceAccounts

This chart installs a single service account with a `cluster-admin` `ClusterRoleBinding`.
