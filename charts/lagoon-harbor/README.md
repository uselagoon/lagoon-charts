# Harbor

This chart installs Lagoon's container registry, [Harbor](https://github.com/goharbor/harbor), in a high availability configuration.

## Prerequisites

Installing this chart requires the use of pre-existing highly available redis and postgres datastores as well as a backend storage solution to store registry artifacts.

### Postgres

For the external postgres datastore, the `registry` database must be created and accessible to the specified user prior to using this datastore with Harbor.

### Redis

For the external redis datastore, no additiona configuration is required.

### Storage Backend

Many storage backends are supported; details can be found in the [harbor-helm chart](https://github.com/goharbor/harbor-helm/blob/master/README.md).

## Quick Start

Here is a minimal sensible `values.yaml`:

```yaml
persistence:
  enabled: true
  resourcePolicy: keep
  imageChartStorage:
    type: gcs
    gcs:
      bucket: bucket-name
      encodedkey: "base64 encoded service account key file contents"
redis:
  type: external
  external:
    host: 169.254.1.1
database:
  type: external
  external:
    host: "169.254.1.1"
    username: postgres
    password: postgrespassword
notary:
  enabled: false
clair:
  enabled: false
trivy:
  enabled: true
chartmuseum:
  enabled: false
expose:
  type: ingress
  ingress: 
    controller: default
    hosts:
      core: "external.url"
    annotations:
      kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "nginx"
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      meta.helm.sh/release-namespace: lagoon
      meta.helm.sh/release-name: harbor
      app.kubernetes.io/managed-by: Helm
  tls:
    enabled: true
internalTLS:
  enabled: true
externalURL: https://external.url
harborAdminPassword: Harbor12345
secretkey: not-a-secure-key
portal:
  replicas: 2
core:
  replicas: 2
  secret: 16charstring1234
jobservice:
  replicas: 2
  secret: 16charstring1234
  jobLogger: stdout
registry:
  replicas: 2
  secret: 16charstring1234
trivy:
  replicas: 2
logLevel: info
relativeurls: true
```
