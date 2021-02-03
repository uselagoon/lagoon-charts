# Lagoon Test

This chart runs the Lagoon test suite.

See the `test-suite` github workflow in this repository for how this chart is used in CI.

## Prerequisites

These tools must be installed:

* `helm` (>=3.2.4)
* `jq` (>=1.6) (or [`gojq`](https://github.com/itchyny/gojq) installed as `jq`)
* `kubectl`
* `make`

Add these helm repositories:

```
helm repo add harbor https://helm.goharbor.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add stable https://charts.helm.sh/stable
```

Also make sure that your local DNS resolver doesn't filter private IPs, or point `/etc/resolv.conf` to `1.0.0.1` / `8.8.8.8`.

## Usage

Create a `kind` cluster.

```
make create-kind-cluster
```

IMPORTANT NOTE: the next step installs several charts using `helm`, so make sure you are in the context of the `kind` cluster installed in the previous step!

Install test fixtures and configure test CI values.

```
# TESTS are a comma-separated list.
# see .github/workflows/test-suite.yaml for valid TESTS.
make -j8 -O fill-test-ci-values TESTS=[features-kubernetes]
helm upgrade \
  --install \
  --namespace lagoon \
  --wait \
  --timeout 15m \
  --values ./charts/lagoon-test/ci/linter-values.yaml \
  lagoon-test \
  ./charts/lagoon-test
```

Lagoon tests can then be run like so:

```
make run-tests
```

Watch the test output in another terminal:

```
kubectl -n lagoon logs -f lagoon-test-test-suite
```

## Tips & Tricks

If you're working on lagoon and want to edit a service image for testing the easiest thing to do is make the changes, push it to a public repo, and override image values in the chart.

For example:

```
# in the lagoon repo
rm -f build/tests && make -j$(getconf _NPROCESSORS_ONLN) DOCKER_BUILD_PARAMS= build/tests && docker tag lagoon/tests smlx/tests && docker push smlx/tests
# override lagoon-test image defaults
helm upgrade \
  --install \
  --namespace lagoon \
  --wait \
  --timeout 15m \
  --values ./charts/lagoon-test/ci/linter-values.yaml \
  --set tests.image.repository=smlx/tests \
  --set tests.image.tag=latest \
  lagoon-test \
  ./charts/lagoon-test
```
