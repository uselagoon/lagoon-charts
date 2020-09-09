# Lagoon Helm charts

[![Actions Status](https://github.com/uselagoon/lagoon-charts/workflows/Release%20Charts/badge.svg)](https://github.com/uselagoon/lagoon-charts/actions)

This repository contains [Helm](https://helm.sh/) charts related to [Lagoon](https://github.com/amazeeio/lagoon/).

## Usage

See [here](https://uselagoon.github.io/lagoon-charts/).

## Contribute

Branch/fork and add/edit a chart in the `charts/` directory.
When you create a PR your change will be automatically linted and tested.
PRs are not mergeable until lint + test passes.

### New charts

Please ensure that any new chart:

* is installable into `kind`, which is used in the CI environment.
  You can add a `ci/linter-values.yaml` file if necessary ([example](https://github.com/uselagoon/lagoon-charts/blob/master/charts/lagoon-logging/ci/linter-values.yaml)).
* has some kind of test, even if it is just a simple connection test ([example](https://github.com/uselagoon/lagoon-charts/blob/master/charts/lagoon-logging/templates/tests/test-connection.yaml)).
* has a useful `templates/NOTES.txt`.
* has a `README.md` with some basic information about the chart.

#### Bonus points: well-tuned probes

The CI runs in a [constrained environment](https://docs.github.com/en/actions/reference/virtual-environments-for-github-hosted-runners#supported-runners-and-hardware-resources) which makes it a good place to test how your chart handles slow-starting pods.
Ideally pods should never be killed due to failing liveness probes during chart-install, even if they do eventually start and the chart installation succeeds.
Documentation on probes for pod startup is [here](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes).
