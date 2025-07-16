TESTS = [api]
# IMAGE_TAG controls the tag used for container images in the lagoon-core,
# lagoon-remote, and lagoon-test charts. If IMAGE_TAG is not set, it will fall
# back to the version set in the CI values file, then to the chart default.
IMAGE_TAG =

# UI_IMAGE_REPO and UI_IMAGE_TAG are an easy way to override the UI image used
# only works for installations where INSTALL_STABLE_CORE=false
# UI_IMAGE_REPO = uselagoon/ui
# UI_IMAGE_TAG = latest

# SSHPORTALAPI_IMAGE_REPO and SSHPORTALAPI_IMAGE_TAG are an easy way to override the ssh portal api image used in the local stack lagoon-core
# only works for installations where INSTALL_STABLE_CORE=false
# SSHPORTALAPI_IMAGE_REPO =
# SSHPORTALAPI_IMAGE_TAG =

# SSHTOKEN_IMAGE_REPO and SSHTOKEN_IMAGE_TAG are an easy way to override the ssh token image used in the local stack lagoon-core
# only works for installations where INSTALL_STABLE_CORE=false
# SSHTOKEN_IMAGE_REPO =
# SSHTOKEN_IMAGE_TAG =

# SSHPORTAL_IMAGE_REPO and SSHPORTAL_IMAGE_TAG are an easy way to override the ssh portal image used in the local stack lagoon-remote
# only works for installations where INSTALL_STABLE_REMOTE=false
# SSHPORTAL_IMAGE_REPO =
# SSHPORTAL_IMAGE_TAG =

LAGOON_CORE_USE_HTTPS = true

# IMAGE_REGISTRY controls the registry used for container images in the
# lagoon-core, lagoon-remote, and lagoon-test charts. If IMAGE_REGISTRY is not
# set, it will fall back to the version set in the chart values files. This
# only affects lagoon-core, lagoon-remote, and the fill-test-ci-values target.
IMAGE_REGISTRY = uselagoon
# if OVERRIDE_BUILD_DEPLOY_DIND_IMAGE is not set, it will fall back to the
# controller default (uselagoon/kubectl-build-deploy-dind:latest).
OVERRIDE_BUILD_DEPLOY_DIND_IMAGE =
# if OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE is not set, it will fall back to the
# controller default (uselagoon/task-activestandby:${lagoonVersion}).
OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE =
# Overrides the image tag for amazeeio/lagoon-builddeploy whose default is
# the lagoon-build-deploy chart appVersion.
OVERRIDE_REMOTE_CONTROLLER_IMAGETAG =
# Overrides the image repository for amazeeio/lagoon-builddeploy whose default
# is the amazeeio/lagoon-builddeploy.
OVERRIDE_REMOTE_CONTROLLER_IMAGE_REPOSITORY =
# If set, sets the lagoon-build-deploy chart .Value.rootless=true.
REMOTE_CONTROLLER_ROOTLESS_BUILD_PODS =
# Control the feature flags on the lagoon-build-deploy chart. Valid values: `enabled` or `disabled`.
LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD = enabled
LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY = enabled
LAGOON_FEATURE_FLAG_DEFAULT_RWX_TO_RWO = enabled
# Set to `true` to use the Calico CNI plugin instead of the default kindnet. This
# is useful for testing network policies.
USE_CALICO_CNI =
# Set to `true` to assume that `make install-registry` has been run manually.
# This avoids running install-registry twice in uselagoon/lagoon CI when
# invoking fill-test-ci-values.
SKIP_INSTALL_REGISTRY =
# Set to `true` to assume that all dependencies have already been installed.
# This allows updating the fill-test-ci-values template only, without
# installing any chart dependencies.
SKIP_ALL_DEPS =
# Set to `true` to use the disable harbor integration in lagoon-core
DISABLE_CORE_HARBOR =
# Set to `true` to enable the elements of lagoon-core that talk to OpenSearch installs
OPENSEARCH_INTEGRATION_ENABLED = false
# Ordinarily we shouldn't need to clear the API data as it's usually a first run. Set this
# variable on a test run to clear (what's clearable) first
CLEAR_API_DATA = false
DOCKER_NETWORK = kind
LAGOON_SSH_PORTAL_LOADBALANCER =
CORE_DATABASE_VENDOR = mariadb

# this should not need to be changed in regular instances, only used by lint tests at the moment
# it is used to stop metallb from being installed when certmanager is installed for the tests
INSTALL_CERTMANAGER_METALLB = true

# install lagoon dependencies by default with the install-lagoon target
INSTALL_LAGOON_DEPENDENCIES = true

# don't install stable charts by default
INSTALL_STABLE_CORE = false
INSTALL_STABLE_REMOTE = false
INSTALL_STABLE_BUILDDEPLOY = false

# unset will install latest released chart version
STABLE_CORE_CHART_VERSION = 
STABLE_REMOTE_CHART_VERSION = 
STABLE_BUILDDEPLOY_CHART_VERSION = 

# verions of core before this version didn't use tls on the broker by default
# setting this ensures that when the lagoon-build-deploy chart is installed with the stable flag
# that if the core version is one that didn't have broker tls enabled in stable
# that it will disable the broker tls settings in lagoon-build-deploy
STABLE_CORE_CHART_VERSION_PRE_BROKER_TLS = 1.52.0

INSTALL_UNAUTHENTICATED_REGISTRY = false

# don't install mailpit in charts ci
INSTALL_MAILPIT = false

# don't install prometheus in charts ci
INSTALL_PROMETHEUS = false

# install dbaas providers by default
INSTALL_MARIADB_PROVIDER = true
INSTALL_POSTGRES_PROVIDER = true
INSTALL_MONGODB_PROVIDER = true

LOGS2SLACK_DISABLED = false
LOGS2EMAIL_DISABLED = false
LOGS2ROCKETCHAT_DISABLED = true
LOGS2EMAIL_DISABLED = false
LOGS2MICROSOFTTEAMS_DISABLED = true

# install k8up v1 (backup.appuio.ch/v1alpah1) and v2 (k8up.io/v1)
# specifify which version the remote controller should start with
# currently lagoon supports both versions, but may one day only support k8up v2
# this can be used to verify upgrades
# by default this will not be install in charts testing, but uselagoon/lagoon can consume it for local development
INSTALL_K8UP = false
REMOTE_CONTROLLER_K8UP_VERSION = v2

TIMEOUT = 30m
HELM = helm
KUBECTL = kubectl
JQ = jq

.PHONY: fill-test-ci-values
fill-test-ci-values:
	export ingressIP="$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" \
		&& export keycloakAuthServerClientSecret="$$($(KUBECTL) -n lagoon-core get secret lagoon-core-keycloak -o json | $(JQ) -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="a.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		&& export routeSuffixHTTPS="a.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		&& export token="$$($(KUBECTL) -n lagoon get secret lagoon-remote-ssh-core-token -o json | $(JQ) -r '.data.token | @base64d')" \
		&& export $$([ $(IMAGE_TAG) ] && echo imageTag='$(IMAGE_TAG)' || echo imageTag='latest') \
		&& export webhookHandler="lagoon-core-webhook-handler" \
		&& export tests='$(TESTS)' imageRegistry='$(IMAGE_REGISTRY)' clearApiData='$(CLEAR_API_DATA)' \
		&& valueTemplate=charts/lagoon-test/ci/linter-values.yaml \
		&& envsubst < $$valueTemplate.tpl > $$valueTemplate \
		&& cat $$valueTemplate

# metallb is used to allow access to the ingress within kubernetes without having to specify a node port
# it picks a small range from the end of the network used by the cluster
.PHONY: install-metallb
install-metallb:
	LAGOON_KIND_CIDR_BLOCK=$$(docker network inspect $(DOCKER_NETWORK) | $(JQ) '. [0].IPAM.Config[0].Subnet' | tr -d '"') && \
	export LAGOON_KIND_NETWORK_RANGE=$$(echo $${LAGOON_KIND_CIDR_BLOCK%???} | awk -F'.' '{print $$1,$$2,$$3,240}' OFS='.')/29 && \
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace metallb-system  \
		--wait \
		--timeout $(TIMEOUT) \
		--version=v0.14.9 \
		metallb \
		metallb/metallb && \
	$$(envsubst < test-suite.metallb-pool.yaml.tpl > test-suite.metallb-pool.yaml) && \
	$(KUBECTL) apply -f test-suite.metallb-pool.yaml

# cert-manager is used to allow self-signed certificates to be generated automatically by ingress in the same way lets-encrypt would
# this allows for the registry and other services to use certificates
.PHONY: install-certmanager
ifeq ($(INSTALL_CERTMANAGER_METALLB),true)
install-certmanager: install-metallb
endif
install-certmanager: generate-ca
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace cert-manager \
		--wait \
		--timeout $(TIMEOUT) \
		--set installCRDs=true \
		--set ingressShim.defaultIssuerName=lagoon-testing-issuer \
		--set ingressShim.defaultIssuerKind=ClusterIssuer \
		--set ingressShim.defaultIssuerGroup=cert-manager.io \
		--version=v1.12.6 \
		cert-manager \
		jetstack/cert-manager
	if [ ! $$($(KUBECTL) -n cert-manager get secret lagoon-test-secret 2>/dev/null || false) ]; then \
		$(KUBECTL) -n cert-manager create secret generic lagoon-test-secret --from-file=tls.crt=certs/rootCA.pem --from-file=tls.key=certs/rootCA-key.pem --from-file=ca.crt=certs/rootCA.pem; \
		$(KUBECTL) apply -f test-suite.certmanager-issuer-ss.yaml; \
	fi

.PHONY: install-ingress
install-ingress: install-certmanager
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace ingress-nginx \
		--wait \
		--timeout $(TIMEOUT) \
		--set controller.allowSnippetAnnotations=true \
		--set controller.enableAnnotationValidations=false \
		--set controller.service.type=LoadBalancer \
		--set controller.service.nodePorts.http=32080 \
		--set controller.service.nodePorts.https=32443 \
		--set controller.config.annotations-risk-level=Critical \
		--set controller.config.proxy-body-size=0 \
		--set controller.config.hsts="false" \
		--set controller.watchIngressWithoutClass=true \
		--set controller.ingressClassResource.default=true \
		--version=4.12.1 \
		ingress-nginx \
		ingress-nginx/ingress-nginx

.PHONY: install-registry
ifeq ($(INSTALL_UNAUTHENTICATED_REGISTRY),false)
install-registry: install-ingress
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace registry \
		--wait \
		--timeout $(TIMEOUT) \
		--set expose.tls.enabled=true \
		--set expose.tls.certSource=secret \
		--set expose.tls.secret.secretName=harbor-ingress \
		--set expose.ingress.className=nginx \
		--set-string expose.ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set "expose.ingress.hosts.core=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "externalURL=https://registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set chartmuseum.enabled=false \
		--set clair.enabled=false \
		--set notary.enabled=false \
		--set trivy.enabled=false \
		--version=1.16.2 \
		registry \
		harbor/harbor
else
# install an unauthenticated registry (https://helm.twun.io) instead of harbor
# useful for arm based systems until harbor supports arm
install-registry: install-ingress
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace registry \
		--wait \
		--timeout $(TIMEOUT) \
		--set ingress.enabled=true \
		--set-string ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set ingress.tls[0].secretName=registry-docker-registry-tls \
		--set ingress.tls[0].hosts[0]=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set "ingress.hosts[0]=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set ingress.path="/" \
		--set persistence.enabled=true \
		--version=2.2.3 \
		registry \
		twuni/docker-registry
endif

.PHONY: install-prometheus
install-prometheus:
	@$(KUBECTL) create namespace kube-prometheus 2>/dev/null || true
	@$(KUBECTL) --namespace kube-prometheus apply -f ci/grafana-dashboards/ssh-portal.yaml
	@$(KUBECTL) --namespace kube-prometheus apply -f ci/grafana-dashboards/keycloak-troubleshoot.yaml
	@$(KUBECTL) --namespace kube-prometheus apply -f ci/grafana-dashboards/keycloak-capacity.yaml
	@$(HELM) upgrade \
		--install --create-namespace \
		--namespace kube-prometheus \
		--wait \
		--timeout $(TIMEOUT) \
		--version 75.9.0 \
		--set grafana.ingress.enabled=true \
		--set grafana.sidecar.dashboards.enabled=true \
		--set grafana.ingress.hosts[0]="grafana.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set grafana.ingress.tls[0].hosts[0]="grafana.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set grafana.ingress.tls[0].secretName=grafana-tls \
		--set-string grafana.ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set-string grafana.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect=false \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
		kube-prometheus prometheus-community/kube-prometheus-stack

.PHONY: install-mailpit
install-mailpit:
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace mailpit \
		--wait \
		--timeout $(TIMEOUT) \
		--set ingress.enabled=true \
		--set-string ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set "ingress.hostname=mailpit.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--version=0.18.6 \
		mailpit \
		jouve/mailpit

.PHONY: install-mariadb
install-mariadb:
	# root password is required on upgrade if the chart is already installed
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace mariadb \
		--wait \
		--timeout $(TIMEOUT) \
		$$($(KUBECTL) get ns mariadb > /dev/null 2>&1 && echo --set auth.rootPassword=$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')) \
		--version=12.2.9 \
		mariadb \
		bitnami/mariadb

.PHONY: install-postgresql
install-postgresql:
	# root password is required on upgrade if the chart is already installed
	# use postgres 14.15.0 image because 15+ have some permission issue
	# 14.15.0-debian-12-r1 is multiarch though
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace postgresql \
		--wait \
		--timeout $(TIMEOUT) \
		--set image.tag="14.15.0-debian-12-r1" \
		$$($(KUBECTL) get ns postgresql > /dev/null 2>&1 && echo --set auth.postgresPassword=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')) \
		--version=16.2.3 \
		postgresql \
		bitnami/postgresql

.PHONY: install-mongodb
install-mongodb:
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace mongodb \
		--wait \
		--timeout $(TIMEOUT) \
		$$($(KUBECTL) get ns mongodb > /dev/null 2>&1 && echo --set auth.rootPassword=$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')) \
		--set tls.enabled=false \
		--version=12.1.31 \
		mongodb \
		bitnami/mongodb

.PHONY: install-minio
install-minio: install-ingress
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace minio \
		--wait \
		--timeout $(TIMEOUT) \
		--set auth.rootUser=lagoonFilesAccessKey,auth.rootPassword=lagoonFilesSecretKey \
		--set defaultBuckets='lagoon-files\,restores' \
		--set ingress.enabled=true \
		--set ingress.hostname=minio.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set apiIngress.enabled=true \
		--set apiIngress.hostname=minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--version=13.6.2 \
		minio \
		bitnami/minio

.PHONY: install-k8upv1
install-k8upv1:
	$(KUBECTL) create -f https://github.com/vshn/k8up/releases/download/v1.2.0/k8up-crd.yaml || \
		$(KUBECTL) replace -f https://github.com/vshn/k8up/releases/download/v1.2.0/k8up-crd.yaml
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace k8upv1 \
		--wait \
		--timeout $(TIMEOUT) \
		--set k8up.envVars[0].name=BACKUP_GLOBALS3ENDPOINT,k8up.envVars[0].value=http://minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[1].name=BACKUP_GLOBALRESTORES3ENDPOINT,k8up.envVars[1].value=http://minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[2].name=BACKUP_GLOBALSTATSURL,k8up.envVars[2].value=http://lagoon-backups.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[3].name=BACKUP_GLOBALACCESSKEYID,k8up.envVars[3].value=lagoonFilesAccessKey \
		--set k8up.envVars[4].name=BACKUP_GLOBALSECRETACCESSKEY,k8up.envVars[4].value=lagoonFilesSecretKey \
		--set k8up.envVars[5].name=BACKUP_GLOBALRESTORES3BUCKET,k8up.envVars[5].value=baas-restores \
		--set k8up.envVars[6].name=BACKUP_GLOBALRESTORES3ACCESSKEYID,k8up.envVars[6].value=lagoonFilesAccessKey \
		--set k8up.envVars[7].name=BACKUP_GLOBALRESTORES3SECRETACCESSKEY,k8up.envVars[7].value=lagoonFilesSecretKey \
		--version=1.1.0 \
		k8upv1 \
		appuio/k8up

# renovate: datasource=github-releases depName=k8up-io/k8up
K8UPV2_VERSION ?= 4.8.4
.PHONY: install-k8upv2
install-k8upv2:
	$(KUBECTL) create -f https://github.com/k8up-io/k8up/releases/download/k8up-$(K8UPV2_VERSION)/k8up-crd.yaml || \
		$(KUBECTL) replace -f https://github.com/k8up-io/k8up/releases/download/k8up-$(K8UPV2_VERSION)/k8up-crd.yaml
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace k8upv2 \
		--wait \
		--timeout $(TIMEOUT) \
		--set k8up.envVars[0].name=BACKUP_GLOBALS3ENDPOINT,k8up.envVars[0].value=http://minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[1].name=BACKUP_GLOBALRESTORES3ENDPOINT,k8up.envVars[1].value=http://minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[2].name=BACKUP_GLOBALSTATSURL,k8up.envVars[2].value=http://lagoon-backups.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set k8up.envVars[3].name=BACKUP_GLOBALACCESSKEYID,k8up.envVars[3].value=lagoonFilesAccessKey \
		--set k8up.envVars[4].name=BACKUP_GLOBALSECRETACCESSKEY,k8up.envVars[4].value=lagoonFilesSecretKey \
		--set k8up.envVars[5].name=BACKUP_GLOBALRESTORES3BUCKET,k8up.envVars[5].value=baas-restores \
		--set k8up.envVars[6].name=BACKUP_GLOBALRESTORES3ACCESSKEYID,k8up.envVars[6].value=lagoonFilesAccessKey \
		--set k8up.envVars[7].name=BACKUP_GLOBALRESTORES3SECRETACCESSKEY,k8up.envVars[7].value=lagoonFilesSecretKey \
		--version=$(K8UPV2_VERSION) \
		k8upv2 \
		k8up/k8up

# generate-ca will generate a CA certificate that will be used to issue certificates
# this CA certificate can be loaded into a web browser so that certificates don't present warnings
.PHONY: generate-ca
generate-ca:
	@ mkdir -p certs && \
	openssl x509 -enddate -noout -in certs/rootCA.pem > /dev/null 2>&1 || \
	(openssl genrsa -out certs/rootCA-key.pem 2048 && \
	openssl req -x509 -new -nodes -key certs/rootCA-key.pem \
		-sha256 -days 3560 -out certs/rootCA.pem -addext keyUsage=critical,digitalSignature,keyEncipherment,keyCertSign \
		-subj '/CN=lagoon.test')

.PHONY: install-lagoon-dependencies
# this will install all the Lagoon dependencies prior to anything related to Lagoon being installed
# this allows for only Lagoon core, remote, or the build-deploy chart to be installed or upgraded without having
# to re-run all the initial dependencies
install-lagoon-dependencies: install-registry install-minio install-bulk-storageclass
ifeq ($(INSTALL_MAILPIT),true)
install-lagoon-dependencies: install-mailpit
endif
ifeq ($(INSTALL_PROMETHEUS),true)
install-lagoon-dependencies: install-prometheus
endif
ifeq ($(INSTALL_MARIADB_PROVIDER),true)
install-lagoon-dependencies: install-mariadb
endif
ifeq ($(INSTALL_POSTGRES_PROVIDER),true)
install-lagoon-dependencies: install-postgresql
endif
ifeq ($(INSTALL_MONGODB_PROVIDER),true)
install-lagoon-dependencies: install-mongodb
endif
# install k8up versions for backup upgrade path verifications if requested
ifeq ($(INSTALL_K8UP),true)
install-lagoon-dependencies: install-k8upv1 install-k8upv2
endif

# this installs lagoon-core, lagoon-remote, and lagoon-build-deploy, and if dependencies required will install them too
.PHONY: install-lagoon
ifeq ($(INSTALL_LAGOON_DEPENDENCIES),true)
install-lagoon: install-lagoon-dependencies
endif
install-lagoon: install-lagoon-core install-lagoon-remote install-lagoon-build-deploy

# this is only used by lint tests at the moment
.PHONY: install-broker-certs
install-broker-certs: install-lagoon-core-broker-certs install-lagoon-remote-broker-certs

# this should not need to be changed in regular instances, only used by lint tests at the moment
CORE_NAMESPACE = lagoon-core
.PHONY: install-lagoon-core-broker-certs
install-lagoon-core-broker-certs:
# create the namespace if it doesn't exist so we can request a certificate from our local testing CA for the broker
	$(KUBECTL) create namespace $(CORE_NAMESPACE) 2>/dev/null || true
	$(KUBECTL) -n $(CORE_NAMESPACE) apply -f broker-core-certificate-request.yaml

.PHONY: install-lagoon-core
install-lagoon-core: install-lagoon-core-broker-certs
ifneq ($(INSTALL_STABLE_CORE),true)
	$(HELM) dependency build ./charts/lagoon-core/
else
ifeq (,$(subst ",,$(STABLE_CORE_CHART_VERSION)))
	$(eval STABLE_CORE_CHART_VERSION = $(shell $(HELM) search repo lagoon/lagoon-core -o json | $(JQ) -r '.[]|.version'))
endif
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon-core \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_CORE) = true ] && [ $(STABLE_CORE_CHART_VERSION) ] && echo '--version=$(STABLE_CORE_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_CORE) = true ]; then echo '--values https://raw.githubusercontent.com/uselagoon/lagoon-charts/refs/tags/lagoon-core-$(STABLE_CORE_CHART_VERSION)/charts/lagoon-core/ci/linter-values.yaml'; else echo '--values ./charts/lagoon-core/ci/linter-values.yaml'; fi) \
		$$([ $(IMAGE_TAG) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set overwriteActiveStandbyTaskImage=$(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set buildDeployImage.default.image=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(DISABLE_CORE_HARBOR) ] && echo '--set api.additionalEnvs.DISABLE_CORE_HARBOR=$(DISABLE_CORE_HARBOR)') \
		--set api.additionalEnvs.ENABLE_SAVED_HISTORY_EXPORT="true" \
		$$([ $(OPENSEARCH_INTEGRATION_ENABLED) ] && echo '--set api.additionalEnvs.OPENSEARCH_INTEGRATION_ENABLED=$(OPENSEARCH_INTEGRATION_ENABLED)') \
		--set "keycloakFrontEndURL=$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonAPIURL=$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/graphql" \
		--set "lagoonUIURL=$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonWebhookURL=http://lagoon-webhook.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set actionsHandler.image.repository=$(IMAGE_REGISTRY)/actions-handler') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set api.image.repository=$(IMAGE_REGISTRY)/api') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiDB.image.repository=$(IMAGE_REGISTRY)/api-db') \
		--set apiDB.vendor=$(CORE_DATABASE_VENDOR) \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiRedis.image.repository=$(IMAGE_REGISTRY)/api-redis') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set authServer.image.repository=$(IMAGE_REGISTRY)/auth-server') \
		--set autoIdler.enabled=false \
		--set backupHandler.enabled=$(INSTALL_K8UP) \
		--set backupHandler.ingress.enabled=true \
		--set backupHandler.ingress.hosts[0].host="lagoon-backups.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set backupHandler.ingress.hosts[0].paths[0]="/" \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set backupHandler.image.repository=$(IMAGE_REGISTRY)/backup-handler') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set broker.image.repository=$(IMAGE_REGISTRY)/broker') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiSidecarHandler.image.repository=$(IMAGE_REGISTRY)/api-sidecar-handler') \
		--set insightsHandler.enabled=false \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set keycloak.image.repository=$(IMAGE_REGISTRY)/keycloak') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set keycloakDB.image.repository=$(IMAGE_REGISTRY)/keycloak-db') \
		--set keycloakDB.vendor=$(CORE_DATABASE_VENDOR) \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set logs2notifications.image.repository=$(IMAGE_REGISTRY)/logs2notifications') \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set logs2notifications.additionalEnvs.EMAIL_HOST=mailpit-smtp.mailpit.svc') \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set logs2notifications.additionalEnvs.EMAIL_PORT=25') \
		$$([ $(INSTALL_PROMETHEUS) = true ] && echo '--set keycloak.serviceMonitor.enabled=true') \
		$$([ $(INSTALL_PROMETHEUS) = true ] && echo '--set sshPortalAPI.serviceMonitor.enabled=true') \
		$$([ $(INSTALL_PROMETHEUS) = true ] && echo '--set sshToken.serviceMonitor.enabled=true') \
		$$([ $(INSTALL_PROMETHEUS) = true ] && echo '--set broker.serviceMonitor.enabled=true') \
		--set logs2notifications.logs2email.disabled=$(LOGS2EMAIL_DISABLED) \
		--set logs2notifications.logs2microsoftteams.disabled=$(LOGS2MICROSOFTTEAMS_DISABLED) \
		--set logs2notifications.logs2rocketchat.disabled=$(LOGS2ROCKETCHAT_DISABLED) \
		--set logs2notifications.logs2slack.disabled=$(LOGS2SLACK_DISABLED) \
		--set logs2notifications.logs2webhooks.disabled=$(LOGS2WEBHOOKS_DISABLED) \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set ssh.image.repository=$(IMAGE_REGISTRY)/ssh') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set webhookHandler.image.repository=$(IMAGE_REGISTRY)/webhook-handler') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set webhooks2tasks.image.repository=$(IMAGE_REGISTRY)/webhooks2tasks') \
		--set s3BAASAccessKeyID=lagoonFilesAccessKey \
		--set s3BAASSecretAccessKey=lagoonFilesSecretKey \
		--set s3FilesAccessKeyID=lagoonFilesAccessKey \
		--set s3FilesSecretAccessKey=lagoonFilesSecretKey \
		--set s3FilesBucket=lagoon-files \
		--set s3FilesHost=http://minio-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io \
		--set api.ingress.enabled=true \
		--set api.ingress.hosts[0].host="lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set api.ingress.hosts[0].paths[0]="/" \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "--set api.ingress.tls[0].hosts[0]=lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set api.ingress.tls[0].secretName=api-tls') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string api.ingress.annotations.kubernetes\\.io/tls-acme=true') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string api.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect=false') \
		--set ui.ingress.enabled=true \
		--set ui.ingress.hosts[0].host="lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set ui.ingress.hosts[0].paths[0]="/" \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "--set ui.ingress.tls[0].hosts[0]=lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set ui.ingress.tls[0].secretName=ui-tls') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string ui.ingress.annotations.kubernetes\\.io/tls-acme=true') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string ui.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect=false') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(UI_IMAGE_REPO) ] && echo '--set ui.image.repository=$(UI_IMAGE_REPO)') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(UI_IMAGE_TAG) ] && echo '--set ui.image.tag=$(UI_IMAGE_TAG)') \
		--set keycloak.ingress.enabled=true \
		--set keycloak.ingress.hosts[0].host="lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set keycloak.ingress.hosts[0].paths[0]="/" \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "--set keycloak.ingress.tls[0].hosts[0]=lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set keycloak.ingress.tls[0].secretName=keycloak-tls') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string keycloak.ingress.annotations.kubernetes\\.io/tls-acme=true') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string keycloak.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect=false') \
		--set webhookHandler.ingress.enabled=true \
		--set webhookHandler.ingress.hosts[0].host="lagoon-webhook.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set webhookHandler.ingress.hosts[0].paths[0]="/" \
		--set-string webhookHandler.ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set broker.ingress.enabled=true \
		--set broker.ingress.hosts[0].host="lagoon-broker.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set broker.ingress.hosts[0].paths[0]="/" \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "--set broker.ingress.tls[0].hosts[0]=lagoon-broker.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set broker.ingress.tls[0].secretName=broker-tls') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string broker.ingress.annotations.kubernetes\\.io/tls-acme=true') \
		$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo '--set-string broker.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect=false') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(SSHPORTALAPI_IMAGE_REPO) ] && echo '--set sshPortalAPI.image.repository=$(SSHPORTALAPI_IMAGE_REPO)') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(SSHPORTALAPI_IMAGE_TAG) ] && echo '--set sshPortalAPI.image.tag=$(SSHPORTALAPI_IMAGE_TAG)') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(SSHTOKEN_IMAGE_REPO) ] && echo '--set sshToken.image.repository=$(SSHTOKEN_IMAGE_REPO)') \
		$$([ $(INSTALL_STABLE_CORE) != true ] && [ $(SSHTOKEN_IMAGE_TAG) ] && echo '--set sshToken.image.tag=$(SSHTOKEN_IMAGE_TAG)') \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set keycloak.email.enabled=true') \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set keycloak.email.settings.host=mailpit-smtp.mailpit.svc') \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set keycloak.email.settings.port=25') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.ports.sshserver=2223') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.port=2020') \
		lagoon-core \
		$$(if [ $(INSTALL_STABLE_CORE) = true ]; then echo 'lagoon/lagoon-core'; else echo './charts/lagoon-core'; fi)
	$(KUBECTL) -n lagoon-core patch deployment lagoon-core-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"SSH_TOKEN_ENDPOINT","value":"lagoon-token.'$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.status.loadBalancer.ingress[0].ip}')'.nip.io"}]}]}}}}'

# this should not need to be changed in regular instances, only used by lint tests at the moment
REMOTE_NAMESPACE = lagoon
.PHONY: install-lagoon-remote-broker-certs
install-lagoon-remote-broker-certs:
# create the namespace if it doesn't exist and add the CA certificate for the remote to use where required
	$(KUBECTL) create namespace $(REMOTE_NAMESPACE) 2>/dev/null || true
	$(KUBECTL) -n $(REMOTE_NAMESPACE) delete secret lagoon-remote-broker-tls 2>/dev/null || true
	$(KUBECTL) -n $(REMOTE_NAMESPACE) create secret generic lagoon-remote-broker-tls --from-file=ca.crt=certs/rootCA.pem

.PHONY: install-lagoon-remote
install-lagoon-remote: install-lagoon-remote-broker-certs
ifneq ($(INSTALL_STABLE_REMOTE),true)
	$(HELM) dependency build ./charts/lagoon-remote/
else
ifeq (,$(subst ",,$(STABLE_REMOTE_CHART_VERSION)))
	$(eval STABLE_REMOTE_CHART_VERSION := $(shell $(HELM) search repo lagoon/lagoon-remote -o json | $(JQ) -r '.[]|.version'))
endif
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_REMOTE) = true ] && [ $(STABLE_REMOTE_CHART_VERSION) ] && echo '--version=$(STABLE_REMOTE_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_REMOTE) = true ]; then echo '--values https://raw.githubusercontent.com/uselagoon/lagoon-charts/refs/tags/lagoon-remote-$(STABLE_REMOTE_CHART_VERSION)/charts/lagoon-remote/ci/linter-values.yaml'; else echo '--values ./charts/lagoon-remote/ci/linter-values.yaml'; fi) \
		--set "lagoon-build-deploy.enabled=false" \
		--set "dockerHost.registry=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.development.environment=development') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.development.hostname=mariadb.mariadb.svc.cluster.local') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.development.password='$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')'') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.development.port=3306') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.development.user=root') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.production.environment=production') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.production.hostname=mariadb.mariadb.svc.cluster.local') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.production.password='$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')'') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.production.port=3306') \
		$$([ $(INSTALL_MARIADB_PROVIDER) = true ] && echo '--set dbaas-operator.mariadbProviders.production.user=root') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.development.environment=development') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.development.hostname=postgresql.postgresql.svc.cluster.local') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.development.password='$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')'') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.development.port=5432') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.development.user=postgres') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.production.environment=production') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.production.hostname=postgresql.postgresql.svc.cluster.local') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.production.password='$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')'') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.production.port=5432') \
		$$([ $(INSTALL_POSTGRES_PROVIDER) = true ] && echo '--set dbaas-operator.postgresqlProviders.production.user=postgres') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.environment=development') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.hostname=mongodb.mongodb.svc.cluster.local') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.password='$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')'') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.port=27017') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.user=root') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.auth.mechanism=SCRAM-SHA-1') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.auth.source=admin') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.development.auth.tls=false') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.environment=production') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.hostname=mongodb.mongodb.svc.cluster.local') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.password='$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')'') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.port=27017') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.user=root') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.auth.mechanism=SCRAM-SHA-1') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.auth.source=admin') \
		$$([ $(INSTALL_MONGODB_PROVIDER) = true ] && echo '--set dbaas-operator.mongodbProviders.production.auth.tls=false') \
		--set "sshCore.enabled=true" \
		$$([ $(INSTALL_MAILPIT) = true ] && echo '--set mxoutHost=mailpit-smtp.mailpit.svc.cluster.local') \
		$$([ $(IMAGE_TAG) ] && [ $(INSTALL_STABLE_REMOTE) != true ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.ports.sshserver=2222') \
		$$([ $(INSTALL_STABLE_REMOTE) != true ] && [ $(SSHPORTAL_IMAGE_REPO) ] && echo '--set sshPortal.image.repository=$(SSHPORTAL_IMAGE_REPO)') \
		$$([ $(INSTALL_STABLE_REMOTE) != true ] && [ $(SSHPORTAL_IMAGE_TAG) ] && echo '--set sshPortal.image.tag=$(SSHPORTAL_IMAGE_TAG)') \
		$$([ $(INSTALL_PROMETHEUS) = true ] && echo '--set sshPortal.serviceMonitor.enabled=true') \
		lagoon-remote \
		$$(if [ $(INSTALL_STABLE_REMOTE) = true ]; then echo 'lagoon/lagoon-remote'; else echo './charts/lagoon-remote'; fi)

# The following target should only be called as a dependency of lagoon-remote
# Do not install without lagoon-core
#
.PHONY: install-lagoon-build-deploy
install-lagoon-build-deploy:
ifneq ($(INSTALL_STABLE_BUILDDEPLOY),true)
	$(HELM) dependency build ./charts/lagoon-build-deploy/
else
ifeq (,$(subst ",,$(STABLE_CORE_CHART_VERSION)))
	$(eval STABLE_CORE_CHART_VERSION = $(shell $(HELM) search repo lagoon/lagoon-core -o json | $(JQ) -r '.[]|.version'))
endif
ifeq (,$(subst ",,$(STABLE_BUILDDEPLOY_CHART_VERSION)))
	$(eval STABLE_BUILDDEPLOY_CHART_VERSION := $(shell $(HELM) search repo lagoon/lagoon-build-deploy -o json | $(JQ) -r '.[]|.version'))
endif
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_BUILDDEPLOY) = true ] && [ $(STABLE_BUILDDEPLOY_CHART_VERSION) ] && echo '--version=$(STABLE_BUILDDEPLOY_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_BUILDDEPLOY) = true ]; then echo '--values https://raw.githubusercontent.com/uselagoon/lagoon-charts/refs/tags/lagoon-build-deploy-$(STABLE_BUILDDEPLOY_CHART_VERSION)/charts/lagoon-build-deploy/ci/linter-values.yaml'; else echo '--values ./charts/lagoon-build-deploy/ci/linter-values.yaml'; fi) \
		--set "rabbitMQPassword=$$($(KUBECTL) -n lagoon-core get secret lagoon-core-broker -o json | $(JQ) -r '.data.RABBITMQ_PASSWORD | @base64d')" \
		--set "lagoonFeatureFlagEnableQoS=true" \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set sshPortalHost=$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.status.loadBalancer.ingress[0].ip}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set sshPortalPort=$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.spec.ports[0].port}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set lagoonTokenHost=$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.status.loadBalancer.ingress[0].ip}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set lagoonTokenPort=$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.spec.ports[0].port}')") \
		--set "QoSMaxBuilds=5" \
		$$([ $(INSTALL_STABLE_CORE) = true ] && [ $(shell expr $(STABLE_CORE_CHART_VERSION) \<= $(STABLE_CORE_CHART_VERSION_PRE_BROKER_TLS)) = 1 ] && echo --set "rabbitMQHostname=lagoon-core-broker.lagoon-core.svc") \
		$$([ $(INSTALL_STABLE_CORE) = true ] && [ $(shell expr $(STABLE_CORE_CHART_VERSION) \<= $(STABLE_CORE_CHART_VERSION_PRE_BROKER_TLS)) = 1 ] && echo --set "broker.tls.enabled=false") \
		$$([ $(REMOTE_CONTROLLER_K8UP_VERSION) = "v2" ] && [ $(INSTALL_K8UP) = true ] && \
			echo "--set extraArgs={--skip-tls-verify=true,--cleanup-harbor-repository-on-delete,--lagoon-feature-flag-support-k8upv2}" || \
			echo "--set extraArgs={--skip-tls-verify=true,--cleanup-harbor-repository-on-delete}") \
		$$([ $(REMOTE_CONTROLLER_K8UP_VERSION) = "v2" ] && [ $(INSTALL_K8UP) = true ] && \
			echo "--set extraEnvs[0].name=LAGOON_FEATURE_FLAG_DEFAULT_K8UP_V2,extraEnvs[0].value=enabled") \
		$$([ $(INSTALL_UNAUTHENTICATED_REGISTRY) = false ] && echo --set "harbor.enabled=true") \
		$$([ $(INSTALL_UNAUTHENTICATED_REGISTRY) = false ] && echo --set "harbor.adminPassword=Harbor12345") \
		$$([ $(INSTALL_UNAUTHENTICATED_REGISTRY) = false ] && echo --set "harbor.adminUser=admin") \
		$$([ $(INSTALL_UNAUTHENTICATED_REGISTRY) = false ] && echo --set "harbor.host=https://registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(INSTALL_UNAUTHENTICATED_REGISTRY) = true ] && echo --set "unauthenticatedRegistry=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io") \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && [ $(INSTALL_STABLE_BUILDDEPLOY) = false ] && echo '--set overrideBuildDeployImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_REMOTE_CONTROLLER_IMAGETAG) ] && [ $(INSTALL_STABLE_BUILDDEPLOY) = false ] && echo '--set image.tag=$(OVERRIDE_REMOTE_CONTROLLER_IMAGETAG)') \
		$$([ $(OVERRIDE_REMOTE_CONTROLLER_IMAGE_REPOSITORY) ] && [ $(INSTALL_STABLE_BUILDDEPLOY) = false ] && echo '--set image.repository=$(OVERRIDE_REMOTE_CONTROLLER_IMAGE_REPOSITORY)') \
		$$([ $(REMOTE_CONTROLLER_ROOTLESS_BUILD_PODS) ] && echo '--set rootlessBuildPods=true') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD) ] && echo '--set lagoonFeatureFlagDefaultRootlessWorkload=$(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD)') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY) ] && echo '--set lagoonFeatureFlagDefaultIsolationNetworkPolicy=$(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY)') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_RWX_TO_RWO) ] && echo '--set lagoonFeatureFlagDefaultRWX2RWO=$(LAGOON_FEATURE_FLAG_DEFAULT_RWX_TO_RWO)') \
		lagoon-build-deploy \
		$$(if [ $(INSTALL_STABLE_BUILDDEPLOY) = true ]; then echo 'lagoon/lagoon-build-deploy'; else echo './charts/lagoon-build-deploy'; fi)
ifeq ($(INSTALL_STABLE_BUILDDEPLOY),true)
	$(HELM) show crds lagoon/lagoon-build-deploy $$([ $(STABLE_BUILDDEPLOY_CHART_VERSION) ] && echo '--version=$(STABLE_BUILDDEPLOY_CHART_VERSION)') | $(KUBECTL) apply -f -
else
	$(KUBECTL) apply -f ./charts/lagoon-build-deploy/crds/crd.lagoon.sh_lagoonbuilds.yaml
	$(KUBECTL) apply -f ./charts/lagoon-build-deploy/crds/crd.lagoon.sh_lagoontasks.yaml
endif

# allow skipping registry install for install-lagoon-remote target
ifneq ($(SKIP_INSTALL_REGISTRY),true)
install-lagoon-build-deploy: install-registry
endif

#
# The following targets facilitate local development only and aren't used in CI.
#

.PHONY: install-bulk-storageclass
install-bulk-storageclass:
	$(KUBECTL) apply -f ./ci/storageclass/local-path-bulk.yaml

.PHONY: create-kind-cluster
create-kind-cluster:
	docker network inspect kind >/dev/null || docker network create kind \
		&& LAGOON_KIND_CIDR_BLOCK=$$(docker network inspect kind | $(JQ) '. [0].IPAM.Config[0].Subnet' | tr -d '"') \
		&& export KIND_NODE_IP=$$(echo $${LAGOON_KIND_CIDR_BLOCK%???} | awk -F'.' '{print $$1,$$2,$$3,240}' OFS='.') \
		&& envsubst < test-suite.kind-config.yaml.tpl > test-suite.kind-config.yaml \
		&& envsubst < test-suite.kind-config.calico.yaml.tpl > test-suite.kind-config.calico.yaml
ifeq ($(USE_CALICO_CNI),true)
	kind create cluster --wait=60s --config=test-suite.kind-config.calico.yaml \
		&& $(KUBECTL) create -f ./ci/calico/tigera-operator.yaml --context kind-chart-testing \
		&& $(KUBECTL) create -f ./ci/calico/custom-resources.yaml --context kind-chart-testing

.PHONY: install-calico
install-calico:
	$(KUBECTL) create -f ./ci/calico/tigera-operator.yaml \
		&& $(KUBECTL) create -f ./ci/calico/custom-resources.yaml

# add dependencies to ensure calico gets installed in the correct order
install-ingress: install-calico
install-registry: install-calico
install-bulk-storageclass: install-calico
install-mariadb: install-calico
install-postgresql: install-calico
install-mongodb: install-calico
install-lagoon-core: install-calico
install-lagoon-remote: install-calico
else
	kind create cluster --wait=60s --config=test-suite.kind-config.yaml
endif

.PHONY: install-test-cluster
install-test-cluster: install-ingress install-registry install-bulk-storageclass install-mariadb install-postgresql install-mongodb install-minio

.PHONY: get-admin-creds
get-admin-creds:
	@echo "\nLagoon UI URL: " \
	&& echo "$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
	&& echo "Lagoon API URL: " \
	&& echo "$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/graphql" \
	&& echo "Lagoon API admin legacy token: \n$$(docker run \
		-e JWTSECRET="$$($(KUBECTL) get secret -n lagoon-core lagoon-core-secrets -o jsonpath="{.data.JWTSECRET}" | base64 --decode)" \
		-e JWTAUDIENCE=api.dev \
		-e JWTUSER=localadmin \
		uselagoon/tests \
		python3 /ansible/tasks/api/admin_token.py)" \
	&& echo "Keycloak admin URL: " \
	&& echo "$$([ $(LAGOON_CORE_USE_HTTPS) = true ] && echo "https" || echo "http")://lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/auth" \
	&& echo "Keycloak admin password: " \
	&& $(KUBECTL) get secret -n lagoon-core lagoon-core-keycloak -o jsonpath="{.data.KEYCLOAK_ADMIN_PASSWORD}" | base64 --decode \
	&& echo "\n"

.PHONY: pf-keycloak pf-api pf-ssh pf-ui pf-broker pf-minio
pf-keycloak:
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-keycloak 8080 2>/dev/null &
pf-api:
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-api 7070:80 2>/dev/null &
pf-ssh:
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-ssh 2020 2>/dev/null &
pf-ui:
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-ui 6060:3000 2>/dev/null &
pf-broker:
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-broker 5672 2>/dev/null &
	$(KUBECTL) port-forward -n lagoon-core svc/lagoon-core-broker 15672 2>/dev/null &
pf-minio:
	$(KUBECTL) port-forward -n minio svc/minio 9000 2>/dev/null &
	$(KUBECTL) port-forward -n minio svc/minio 9001 2>/dev/null &

.PHONY: port-forwards
port-forwards: pf-keycloak pf-api pf-ssh pf-ui

.PHONY: run-tests
run-tests:
	$(HELM) test --namespace lagoon-core --timeout 30m lagoon-test
