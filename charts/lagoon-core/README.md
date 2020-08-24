# Lagoon Core

This chart installs the core services for [Lagoon](https://github.com/amazeeio/lagoon/).

## Configuration

See the comments at the top of `values.yaml`.

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

A minimal sensible `values.yaml` for this chart would set these values:

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
```

Ingress configuration in this case relies on correctly configured DNS and [cert-manager](https://cert-manager.io/docs/usage/ingress/).
