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
logs2webhook:
  enabled: false
storageCalculator:
  enabled: false
webhookHandler:
  enabled: false
webhooks2tasks:
  enabled: false
sshPortal:
  enabled: false
```

## TL;DR Local testing using kind

Prerequisite: download and install the [Lagoon CLI](https://github.com/amazeeio/lagoon-cli).

### Install

Run these commands:

```
kind create cluster

helm upgrade --install --create-namespace --namespace lagoon-core \
  --values ./charts/lagoon-core/ci/linter-values.yaml \
  --set lagoonAPIURL=http://localhost:7070/graphql \
  --set keycloakAPIURL=http://localhost:8080/auth \
  lagoon-core \
  ./charts/lagoon-core

# make a note of the lagoonadmin credentials

kubectl port-forward svc/lagoon-core-keycloak 8080 &
kubectl port-forward svc/lagoon-core-api 7070:80 &
kubectl port-forward svc/lagoon-core-ui 6060:3000 &
kubectl port-forward svc/lagoon-core-ssh 2020 &
```

### Use

1. Visit [http://localhost:6060/](http://localhost:6060/).
2. Log in using the `lagoonadmin` credentials from the helm chart installation.
3. Click settings (top right).
4. Add your ssh key.
5. Add this config to `~/.lagoon.yml`:
```
current: local
default: local
lagoons:
  local:
    graphql: http://localhost:7070/graphql
    hostname: localhost
    port: 2020
    ui: http://localhost:6060
```
6. Check you can log in:
```
$ lagoon whoami
ID                                  	EMAIL	FIRSTNAME	LASTNAME	SSHKEYS
f57455c1-0d6b-491a-9117-89a9763dc940	-    	-        	-       	1
```

At this point `lagoon-core` is installed.
To actually deploy a project a `lagoon-remote` must be configured, which is beyond the scope of this README.

### Uninstall

```
helm uninstall lagoon-core
# clean up the pvcs that kind doesn't reclaim automatically
kubectl delete pvc --all
```

## Quick Start

Here is a super-minimal `values.yaml` for a real Lagoon installation.

Important notes:

* Ingress configuration in this case relies on correctly configured DNS and [cert-manager](https://cert-manager.io/docs/usage/ingress/).
* Because the SSH service is non-http it requires a `LoadBalancer` Service type.

```yaml
elasticsearchURL: http://logs.example.com

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
* The `ssh-portal` (disabled by default, eventually will be moved to `lagoon-remote`, see [amazeeio/lagoon#2179](https://github.com/amazeeio/lagoon/pull/2179)) has a serviceaccount bound to a clusterrole to allow exec into pods.


## Lagoon Files

Lagoon needs to upload files in some specific cases (like when a developer requests an dump of a database, the dump will be store in the Lagoon Files system).
Lagoon uses S3 compatible storage for it, it can be configured via these helm values:


- `s3FilesHost` - S3 Host name, like `https://s3.amazonaws.com` or `https://storage.googleapis.com`
- `s3FilesBucket` - Name of the S3 Bucket
- `s3FilesAccessKeyID` - AccessKey for the S3 Bucket
- `s3FilesSecretAccessKey` - AccessKey Secret for the S3 Bucket
