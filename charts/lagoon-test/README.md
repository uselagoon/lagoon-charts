# Lagoon Test

This chart runs the Lagoon test suite.

## Usage

Create a `kind` cluster and add an ingress controller and registry.

NOTE: check the node IP, it might be different to `172.18.0.2`, in which case adjust the commands below.

```
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.172.18.0.2.nip.io:32443".tls]
    insecure_skip_verify = true
EOF
helm upgrade \
  --install \
  --create-namespace \
  --namespace ingress-nginx \
  --wait \
  --timeout 15m \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=32080 \
  --set controller.service.nodePorts.https=32443 \
  --set controller.config.proxy-body-size=100m \
  ingress-nginx \
  ingress-nginx/ingress-nginx \
&& helm upgrade \
  --install \
  --create-namespace \
  --namespace registry \
  --wait \
  --timeout 15m \
  --set ingress.enabled=true \
  --set "ingress.hosts={registry.$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io}" \
  --set "ingress.annotations.kubernetes\.io\/ingress\.class=nginx" \
  --set "ingress.annotations.nginx\.ingress\.kubernetes\.io\/proxy-body-size=0" \
  registry \
  stable/docker-registry
```

Install `lagoon-core`, `lagoon-remote`, and `lagoon-test` (this chart) into the `lagoon` namespace.

```
helm upgrade \
  --install \
  --create-namespace \
  --namespace lagoon \
  --wait \
  --timeout 15m \
  --values ./charts/lagoon-core/ci/linter-values.yaml \
  --set autoIdler.enabled=false \
  --set drushAlias.enabled=true \
  --set logs2email.enabled=false \
  --set logs2microsoftteams.enabled=false \
  --set logs2rocketchat.enabled=false \
  --set logs2slack.enabled=false \
  --set logsDBCurator.enabled=false \
  --set "registry=registry.$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32443" \
  --set "lagoonAPIURL=http://localhost:7070/graphql" \
  --set "keycloakAPIURL=http://localhost:8080/auth" \
  --set storageCalculator.enabled=false \
  --set sshPortal.enabled=false \
  lagoon-core \
  ./charts/lagoon-core \
&& helm upgrade \
  --install \
  --create-namespace \
  --namespace lagoon \
  --wait \
  --timeout 15m \
  --values ./charts/lagoon-remote/ci/linter-values.yaml \
  --set "rabbitMQPassword=$(kubectl -n lagoon get secret lagoon-core-broker -o json | jq -r '.data.RABBITMQ_PASSWORD | @base64d')" \
  --set "dockerHost.registry=registry.$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32443" \
  lagoon-remote \
  ./charts/lagoon-remote \
&& helm upgrade \
  --install \
  --create-namespace \
  --namespace lagoon \
  --wait \
  --timeout 15m \
  --set "ingressIP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')" \
  --set "keycloakAuthServerClientSecret=$(kubectl -n lagoon get secret lagoon-core-keycloak -o json | jq -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
  --set "routeSuffixHTTP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
  --set "routeSuffixHTTPS=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
  --set "token=$(kubectl -n lagoon get secret -o json | jq -r '.items[] | select(.metadata.name | match("lagoon-build-deploy-token")) | .data.token | @base64d')" \
  lagoon-test \
  ./charts/lagoon-test
```

Lagoon tests can then be run like so:

```
kubens lagoon
helm test --timeout 15m lagoon-test
```

Watch the test output in another terminal:

```
helm logs -f lagoon-test-test-suite
```
