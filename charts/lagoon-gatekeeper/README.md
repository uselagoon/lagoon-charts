# Lagoon Gatekeeper

This chart installs the [gatekeeper](https://github.com/open-policy-agent/gatekeeper) admission controller as well as policies tailored for Lagoon.

## Installation

Gatekeeper works by generating CRDs of `constraints` from `constrainttemplates`.
This means that when you first install Gatekeeper, the CRDs are not created until Gatekeeper parses the configured `constrainttemplates` and creates the associated CRDs.

For this reason this chart must be installed in two stages:

1. install chart with default values. Wait for gatekeeper to create the `*.constraints.gatekeeper.sh` CRDs (`kubectl get crd -w`).
2. install with `--set=constraints.create=true`.

The `constraints.create=false` value stops the chart from trying to create any custom resources which aren't yet defined.

## Policy and chart configuration

There is currently no other configuration for this chart.

Policies will be applied to namespaces with a `lagoon.sh/project` label.

## About

The constraint templates are taken from [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) and generated via:

```
kustomize build library > templates/constrainttemplate.yaml
```
