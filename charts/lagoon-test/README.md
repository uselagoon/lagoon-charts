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
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

Also make sure that your local DNS resolver doesn't filter private IPs, or point `/etc/resolv.conf` to `1.0.0.1` / `8.8.8.8`.

## Usage

IMPORTANT NOTE: after creating the `kind` cluster, check the node IP - it might be different to `172.18.0.2` in which case edit the kind config file to match and recreate the cluster.

Create a `kind` cluster and add an ingress controller and registry.

```
kind create cluster --config=test-suite.kind-config.yaml
```

IMPORTANT NOTE: the next step installs several charts using `helm`, so make sure you are in the context of the `kind` cluster installed in the previous step!

Install test fixtures and configure test CI values.

```
make fill-test-ci-values
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
kubens lagoon
helm test --timeout 30m lagoon-test
```

Watch the test output in another terminal:

```
kubectl -n lagoon logs -f lagoon-test-test-suite
```
