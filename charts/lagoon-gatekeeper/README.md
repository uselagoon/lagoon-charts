# Lagoon Gatekeeper

This chart installs the [gatekeeper](https://github.com/open-policy-agent/gatekeeper) admission controller as well as policies tailored for Lagoon.

## Policy and chart configuration

There is currently no other configuration for this chart.

Policies will be applied to namespaces with a `lagoon.sh/project` label.

## About

The constraint templates are taken from [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) and generated via:

```
kustomize build library > templates/constrainttemplate.yaml
```
