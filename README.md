# amazee.io Helm charts

This repository contains [Helm](https://helm.sh/) charts related to [Lagoon](https://github.com/amazeeio/lagoon/).

## Usage

```
helm repo add amazeeio https://amazeeio.github.io/charts/
```

See individual chart directories for usage.

## Contribute

Branch/fork and add/edit a chart in the `charts/` directory. When you create a PR your change will be automatically linted and tested. PRs are not mergeable until lint + test passes.

### New charts

Please ensure that any new chart:

* is installable into `kind`, which is used in the CI environment. You can add a `ci/linter-values.yaml` file if necessary ([example](https://github.com/amazeeio/charts/blob/master/charts/lagoon-logging/ci/linter-values.yaml)).
* has some kind of test, even if it is just a simple connection test ([example](https://github.com/amazeeio/charts/blob/master/charts/lagoon-logging/templates/tests/test-connection.yaml)).
* has a useful `templates/NOTES.txt`.
* has a `README.md` with some basic information about the chart.
