# Lagoon Core

This chart installs the core services for [Lagoon](https://github.com/amazeeio/lagoon/).

## Configuration

See the comments at the top of `values.yaml`.

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
    - host: lagoon.example.com
      paths: /
    tls:
    - secretName: api-tls
      hosts:
      - lagoon.example.com
```

Ingress configuration in this case relies on correctly configured DNS and [cert-manager](https://cert-manager.io/docs/usage/ingress/).
