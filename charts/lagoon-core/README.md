# Lagoon Core

This chart installs the core services for [Lagoon](https://github.com/amazeeio/lagoon/). See that repository for details on each of the microservices that make up Lagoon.

## Configuration

See the comments at the top of `values.yaml`.

All services are enabled by default. The following auxiliary services can be disabled like so:

```yaml
autoIdler:
  enabled: false
drushAlias:
  enabled: false
logs2email:
  enabled: false
logs2microsoftteams:
  enabled: false
logs2rocketchat:
  enabled: false
logs2slack:
  enabled: false
logsDBCurator:
  enabled: false
storageCalculator:
  enabled: false
webhookHandler:
  enabled: false
webhooks2tasks:
  enabled: false
```

## TL;DR Local testing

Run these commands:

```
kind create cluster

helm upgrade --install --create-namespace --namespace lagoon-core --values ./charts/lagoon-core/ci/linter-values.yaml --set lagoonAPIURL=http://localhost:7070/graphql --set keycloakAPIURL=http://localhost:8080/auth lagoon-core ./charts/lagoon-core

kubectl port-forward svc/lagoon-core-keycloak 8080 &
kubectl port-forward svc/lagoon-core-api 7070:80 &
kubectl port-forward svc/lagoon-core-ui 6060:3000 &
```

Visit [http://localhost:6060/](http://localhost:6060/).

## Quick Start

Here is a minimal sensible `values.yaml`.

Important notes:

* Ingress configuration in this case relies on correctly configured DNS and [cert-manager](https://cert-manager.io/docs/usage/ingress/).
* Because the SSH service is non-http it requires a `LoadBalancer` Service type.

```yaml
elasticsearchHost: logs.example.com

api:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/tls-acme: "true"
    hosts:
    - host: lagoon-api.example.com
      paths: /
    tls:
    - secretName: api-tls
      hosts:
      - lagoon-api.example.com

ui:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/tls-acme: "true"
    hosts:
    - host: lagoon-ui.example.com
      paths: /
    tls:
    - secretName: ui-tls
      hosts:
      - lagoon-ui.example.com

keycloak:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/tls-acme: "true"
    hosts:
    - host: lagoon-keycloak.example.com
      paths: /
    tls:
    - secretName: keycloak-tls
      hosts:
      - lagoon-keycloak.example.com

ssh:
  service:
    type: LoadBalancer
    port: 22
```

## ServiceAccounts

* The `broker` has a serviceaccount bound to a role to allow service discovery for HA clustering.
