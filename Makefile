TESTS = [api]
# IMAGE_TAG controls the tag used for container images in the lagoon-core,
# lagoon-remote, and lagoon-test charts. If IMAGE_TAG is not set, it will fall
# back to the version set in the CI values file, then to the chart default.
IMAGE_TAG =
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
OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG =
# Overrides the image repository for amazeeio/lagoon-builddeploy whose default
# is the amazeeio/lagoon-builddeploy.
OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY =
# If set, sets the lagoon-build-deploy chart .Value.rootless=true.
BUILD_DEPLOY_CONTROLLER_ROOTLESS_BUILD_PODS =
# Control the feature flags on the lagoon-build-deploy chart. Valid values: `enabled` or `disabled`.
LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD =
LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY =
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

# don't install stable charts by default
INSTALL_STABLE_CORE = false
INSTALL_STABLE_REMOTE = false
INSTALL_STABLE_BUILDDEPLOY = false

# unset will install latest released chart version
STABLE_CORE_CHART_VERSION = 
STABLE_REMOTE_CHART_VERSION = 
STABLE_BUILDDEPLOY_CHART_VERSION = 

# install dbaas providers by default
INSTALL_MARIADB_PROVIDER = true
INSTALL_POSTGRES_PROVIDER = true
INSTALL_MONGODB_PROVIDER = true

TIMEOUT = 30m
HELM = helm
KUBECTL = kubectl
JQ = jq

.PHONY: fill-test-ci-values
fill-test-ci-values:
	export ingressIP="$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" \
		&& export keycloakAuthServerClientSecret="$$($(KUBECTL) -n lagoon-core get secret lagoon-core-keycloak -o json | $(JQ) -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		&& export routeSuffixHTTPS="$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		&& export token="$$($(KUBECTL) -n lagoon create token lagoon-build-deploy --duration 3h)" \
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
		--version=v0.13.12 \
		metallb \
		metallb/metallb && \
	$$(envsubst < test-suite.metallb-pool.yaml.tpl > test-suite.metallb-pool.yaml) && \
	$(KUBECTL) apply -f test-suite.metallb-pool.yaml \

# cert-manager is used to allow self-signed certificates to be generated automatically by ingress in the same way lets-encrypt would
.PHONY: install-certmanager
install-certmanager: install-metallb
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
		--version=v1.11.0 \
		cert-manager \
		jetstack/cert-manager
	$(KUBECTL) apply -f test-suite.certmanager-issuer-ss.yaml

.PHONY: install-ingress
install-ingress: install-certmanager
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace ingress-nginx \
		--wait \
		--timeout $(TIMEOUT) \
		--set controller.allowSnippetAnnotations=true \
		--set controller.service.type=LoadBalancer \
		--set controller.service.nodePorts.http=32080 \
		--set controller.service.nodePorts.https=32443 \
		--set controller.config.proxy-body-size=100m \
		--set controller.config.hsts="false" \
		--set controller.watchIngressWithoutClass=true \
		--set controller.ingressClassResource.default=true \
		--version=4.9.1 \
		ingress-nginx \
		ingress-nginx/ingress-nginx

.PHONY: install-registry
install-registry: install-mailpit
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
		--version=1.14.3 \
		registry \
		harbor/harbor

.PHONY: install-mailpit
install-mailpit: install-ingress
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace mailpit \
		--wait \
		--timeout $(TIMEOUT) \
		--set ingress.enabled=true \
		--set-string ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set "ingress.hostname=mailpit.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--version=0.15.3 \
		mailpit \
		jouve/mailpit

.PHONY: install-mariadb
install-mariadb:
ifeq ($(INSTALL_MARIADB_PROVIDER),true)
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
endif

.PHONY: install-postgresql
install-postgresql:
ifeq ($(INSTALL_POSTGRES_PROVIDER),true)
	# root password is required on upgrade if the chart is already installed
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace postgresql \
		--wait \
		--timeout $(TIMEOUT) \
		$$($(KUBECTL) get ns postgresql > /dev/null 2>&1 && echo --set auth.postgresPassword=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')) \
		--version=11.9.13 \
		postgresql \
		bitnami/postgresql
endif

.PHONY: install-mongodb
install-mongodb:
ifeq ($(INSTALL_MONGODB_PROVIDER),true)
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
endif

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
		--version=13.6.2 \
		minio \
		bitnami/minio

# this will install all the Lagoon dependencies prior to anything related to Lagoon being installed
# this allows for only Lagoon core, remote, or the build-deploy chart to be installed or upgraded without having
# to re-run all the initial dependencies
.PHONY: install-lagoon-dependencies
install-lagoon-dependencies: install-registry install-minio install-mariadb install-postgresql install-mongodb install-bulk-storageclass

# this installs lagoon-core, lagoon-remote, and lagoon-build-deploy
.PHONY: install-lagoon
install-lagoon: install-lagoon-core install-lagoon-remote install-lagoon-build-deploy

.PHONY: install-lagoon-core
install-lagoon-core:
ifneq ($(INSTALL_STABLE_CORE),true)
	$(HELM) dependency build ./charts/lagoon-core/
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon-core \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_CORE) = true ] && [ $(STABLE_CORE_CHART_VERSION) ] && echo '--version=$(STABLE_CORE_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_CORE) = true ]; then echo '--values ./charts/lagoon-core/ci/linter-values-stable.yaml'; else echo '--values ./charts/lagoon-core/ci/linter-values.yaml'; fi) \
		$$([ $(IMAGE_TAG) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set overwriteActiveStandbyTaskImage=$(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set buildDeployImage.default.image=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(DISABLE_CORE_HARBOR) ] && echo '--set api.additionalEnvs.DISABLE_CORE_HARBOR=$(DISABLE_CORE_HARBOR)') \
		$$([ $(OPENSEARCH_INTEGRATION_ENABLED) ] && echo '--set api.additionalEnvs.OPENSEARCH_INTEGRATION_ENABLED=$(OPENSEARCH_INTEGRATION_ENABLED)') \
		--set "keycloakFrontEndURL=http://lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonAPIURL=http://lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/graphql" \
		--set "lagoonUIURL=http://lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonWebhookURL=http://lagoon-webhook.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set actionsHandler.image.repository=$(IMAGE_REGISTRY)/actions-handler') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set api.image.repository=$(IMAGE_REGISTRY)/api') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiDB.image.repository=$(IMAGE_REGISTRY)/api-db') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiRedis.image.repository=$(IMAGE_REGISTRY)/api-redis') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set authServer.image.repository=$(IMAGE_REGISTRY)/auth-server') \
		--set autoIdler.enabled=false \
		--set backupHandler.enabled=false \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set broker.image.repository=$(IMAGE_REGISTRY)/broker') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set apiSidecarHandler.image.repository=$(IMAGE_REGISTRY)/api-sidecar-handler') \
		--set insightsHandler.enabled=false \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set keycloak.image.repository=$(IMAGE_REGISTRY)/keycloak') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set keycloakDB.image.repository=$(IMAGE_REGISTRY)/keycloak-db') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set logs2notifications.image.repository=$(IMAGE_REGISTRY)/logs2notifications') \
		--set logs2notifications.email.disabled=true \
		--set logs2notifications.microsoftteams.disabled=true \
		--set logs2notifications.rocketchat.disabled=true \
		--set logs2notifications.slack.disabled=true \
		--set logs2notifications.webhooks.disabled=true \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set ssh.image.repository=$(IMAGE_REGISTRY)/ssh') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set webhookHandler.image.repository=$(IMAGE_REGISTRY)/webhook-handler') \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set webhooks2tasks.image.repository=$(IMAGE_REGISTRY)/webhooks2tasks') \
		--set s3FilesAccessKeyID=lagoonFilesAccessKey \
		--set s3FilesSecretAccessKey=lagoonFilesSecretKey \
		--set s3FilesBucket=lagoon-files \
		--set s3FilesHost=http://minio.minio.svc:9000 \
		--set api.ingress.enabled=true \
		--set api.ingress.hosts[0].host="lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set api.ingress.hosts[0].paths[0]="/" \
		--set ui.ingress.enabled=true \
		--set ui.ingress.hosts[0].host="lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set ui.ingress.hosts[0].paths[0]="/" \
		--set keycloak.ingress.enabled=true \
		--set keycloak.ingress.hosts[0].host="lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set keycloak.ingress.hosts[0].paths[0]="/" \
		--set webhookHandler.ingress.enabled=true \
		--set webhookHandler.ingress.hosts[0].host="lagoon-webhook.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set webhookHandler.ingress.hosts[0].paths[0]="/" \
		--set broker.ingress.enabled=true \
		--set broker.ingress.hosts[0].host="lagoon-broker.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set broker.ingress.hosts[0].paths[0]="/" \
		$$([ $(IMAGE_REGISTRY) ] && [ $(INSTALL_STABLE_CORE) != true ] && echo '--set workflows.image.repository=$(IMAGE_REGISTRY)/workflows') \
		--set keycloak.email.enabled=true \
		--set keycloak.email.settings.host=mailpit-smtp.mailpit.svc \
		--set keycloak.email.settings.port=25 \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.ports.sshserver=2223') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.port=2020') \
		lagoon-core \
		$$(if [ $(INSTALL_STABLE_CORE) = true ]; then echo 'lagoon/lagoon-core'; else echo './charts/lagoon-core'; fi)
	$(KUBECTL) -n lagoon-core patch deployment lagoon-core-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"SSH_TOKEN_ENDPOINT","value":"lagoon-token.'$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.status.loadBalancer.ingress[0].ip}')'.nip.io"}]}]}}}}'

.PHONY: install-lagoon-remote
install-lagoon-remote:
ifneq ($(INSTALL_STABLE_REMOTE),true)
	$(HELM) dependency build ./charts/lagoon-remote/
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_REMOTE) = true ] && [ $(STABLE_REMOTE_CHART_VERSION) ] && echo '--version=$(STABLE_REMOTE_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_REMOTE) = true ]; then echo '--values ./charts/lagoon-remote/ci/linter-values-stable.yaml'; else echo '--values ./charts/lagoon-remote/ci/linter-values.yaml'; fi) \
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
		--set "sshCore.enaled=true" \
		--set "mxoutHost=mailpit-smtp.mailpit.svc.cluster.local" \
		$$([ $(IMAGE_TAG) ] && [ $(INSTALL_STABLE_REMOTE) != true ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.ports.sshserver=2222') \
		lagoon-remote \
		$$(if [ $(INSTALL_STABLE_REMOTE) = true ]; then echo 'lagoon/lagoon-remote'; else echo './charts/lagoon-remote'; fi)

# The following target should only be called as a dependency of lagoon-remote
# Do not install without lagoon-core
#
.PHONY: install-lagoon-build-deploy
install-lagoon-build-deploy:
ifneq ($(INSTALL_STABLE_BUILDDEPLOY),true)
	$(HELM) dependency build ./charts/lagoon-build-deploy/
endif
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		$$([ $(INSTALL_STABLE_BUILDDEPLOY) = true ] && [ $(STABLE_BUILDDEPLOY_CHART_VERSION) ] && echo '--version=$(STABLE_BUILDDEPLOY_CHART_VERSION)') \
		$$(if [ $(INSTALL_STABLE_BUILDDEPLOY) = true ]; then echo '--values ./charts/lagoon-build-deploy/ci/linter-values-stable.yaml'; else echo '--values ./charts/lagoon-build-deploy/ci/linter-values.yaml'; fi) \
		--set "rabbitMQPassword=$$($(KUBECTL) -n lagoon-core get secret lagoon-core-broker -o json | $(JQ) -r '.data.RABBITMQ_PASSWORD | @base64d')" \
		--set "rabbitMQHostname=lagoon-core-broker.lagoon-core.svc" \
		--set "lagoonFeatureFlagEnableQoS=true" \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set sshPortalHost=$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.status.loadBalancer.ingress[0].ip}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set sshPortalPort=$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.spec.ports[0].port}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set lagoonTokenHost=$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.status.loadBalancer.ingress[0].ip}')") \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo "--set lagoonTokenPort=$$($(KUBECTL) -n lagoon-core get services lagoon-core-ssh-token -o jsonpath='{.spec.ports[0].port}')") \
		--set "QoSMaxBuilds=5" \
		--set "harbor.enabled=true" \
		--set "harbor.adminPassword=Harbor12345" \
		--set "harbor.adminUser=admin" \
		--set "harbor.host=https://registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && [ ! $(INSTALL_STABLE_BUILDDEPLOY) ] && echo '--set overrideBuildDeployImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG) ] && [ ! $(INSTALL_STABLE_BUILDDEPLOY) ] && echo '--set image.tag=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY) ] && [ ! $(INSTALL_STABLE_BUILDDEPLOY) ] && echo '--set image.repository=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY)') \
		$$([ $(BUILD_DEPLOY_CONTROLLER_ROOTLESS_BUILD_PODS) ] && echo '--set rootlessBuildPods=true') \
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
	&& echo "http://lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
	&& echo "Lagoon API URL: " \
	&& echo "http://lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/graphql" \
	&& echo "Lagoon API admin legacy token: \n$$(docker run \
		-e JWTSECRET="$$($(KUBECTL) get secret -n lagoon-core lagoon-core-secrets -o jsonpath="{.data.JWTSECRET}" | base64 --decode)" \
		-e JWTAUDIENCE=api.dev \
		-e JWTUSER=localadmin \
		uselagoon/tests \
		python3 /ansible/tasks/api/admin_token.py)" \
	&& echo "Keycloak admin URL: " \
	&& echo "http://lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/auth" \
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
