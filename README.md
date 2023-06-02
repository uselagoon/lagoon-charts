# Lagoon Helm charts

[![Actions Status](https://github.com/uselagoon/lagoon-charts/workflows/Release%20Charts/badge.svg)](https://github.com/uselagoon/lagoon-charts/actions)

This repository contains [Helm](https://helm.sh/) charts related to [Lagoon](https://github.com/amazeeio/lagoon/).

## Table of Contents
1. Project Description
2. Usage
3. Tips & Tricks
4. Contribution

## Project Description
This repository provides the helm charts needed to install the various Lagoon components. It hosts the chart configurations and the chart repository itself (via GitHub pages)

## Usage

`helm repo add lagoon https://uselagoon.github.io/lagoon-charts/`

See individual chart directories for READMEs and usage instructions.


## Tips & Tricks

### Run chart-testing (lint) locally

```
$ docker run --rm --interactive --detach --network host --name ct "--volume=$(pwd):/workdir" "--workdir=/workdir" --volume=$(pwd)/default.ct.yaml:/etc/ct/ct.yaml quay.io/helmpack/chart-testing:latest cat
$ docker exec ct ct lint
```

## Contribution

Branch/fork and add/edit a chart in the `charts/` directory.
When you create a PR your change will be automatically linted and tested.
PRs are not mergeable until lint + test passes.

Releases are automatically made for any change which is merged to `main`.

### How CI works on PRs

* All charts except `lagoon-test` are automatically linted, installed, and tested.
* `lagoon-test` is special since it is used purely for development and consists of test fixtures for the full Lagoon test suite.
* Any change to `lagoon-core`, `lagoon-remote`, or `lagoon-test` trigger a second CI job which installs the three charts together and runs the full test suite.

### New charts

Please ensure that any new chart:

* is installable into `kind`, which is used in the CI environment.
  You can add a `ci/linter-values.yaml` file if necessary ([example](https://github.com/uselagoon/lagoon-charts/blob/master/charts/lagoon-logging/ci/linter-values.yaml)).
* has some kind of test, even if it is just a simple connection test ([example](https://github.com/uselagoon/lagoon-charts/blob/master/charts/lagoon-logging/templates/tests/test-connection.yaml)).
* has a useful `templates/NOTES.txt`.
* has a `README.md` with some basic information about the chart.

#### Bonus points: well-tuned probes

The CI runs in a [constrained environment](https://docs.github.com/en/actions/reference/virtual-environments-for-github-hosted-runners#supported-runners-and-hardware-resources) which makes it a good place to test how your chart handles slow-starting pods.
Ideally pods should never be killed due to failing probes during chart-install, even if they do eventually start and the chart installation succeeds.
Documentation on probes for pod startup is [here](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes).
