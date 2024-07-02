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

ifneq ($(SKIP_ALL_DEPS),true)
ifneq ($(SKIP_INSTALL_REGISTRY),true)
fill-test-ci-values: install-registry
endif
fill-test-ci-values: install-ingress install-lagoon-core install-lagoon-build-deploy install-bulk-storageclass
endif

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
		--set "expose.ingress.annotations.kubernetes\.io\/ingress\.class=nginx" \
		--set-string expose.ingress.annotations.kubernetes\\.io/tls-acme=true \
		--set "expose.ingress.hosts.core=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "externalURL=https://registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set chartmuseum.enabled=false \
		--set clair.enabled=false \
		--set notary.enabled=false \
		--set trivy.enabled=false \
		--version=1.14.0 \
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
		--version=13.6.2 \
		minio \
		bitnami/minio

.PHONY: install-lagoon-core
install-lagoon-core: install-minio
	$(HELM) dependency build ./charts/lagoon-core/
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon-core \
		--wait \
		--timeout $(TIMEOUT) \
		--values ./charts/lagoon-core/ci/linter-values.yaml \
		$$([ $(IMAGE_TAG) ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE) ] && echo '--set overwriteActiveStandbyTaskImage=$(OVERRIDE_ACTIVE_STANDBY_TASK_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set buildDeployImage.default.image=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(DISABLE_CORE_HARBOR) ] && echo '--set api.additionalEnvs.DISABLE_CORE_HARBOR=$(DISABLE_CORE_HARBOR)') \
		$$([ $(OPENSEARCH_INTEGRATION_ENABLED) ] && echo '--set api.additionalEnvs.OPENSEARCH_INTEGRATION_ENABLED=$(OPENSEARCH_INTEGRATION_ENABLED)') \
		--set "keycloakFrontEndURL=http://lagoon-keycloak.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonAPIURL=http://lagoon-api.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io/graphql" \
		--set "lagoonUIURL=http://lagoon-ui.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "lagoonWebhookURL=http://lagoon-webhook.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set actionsHandler.image.repository=$(IMAGE_REGISTRY)/actions-handler  \
		--set api.image.repository=$(IMAGE_REGISTRY)/api \
		--set apiDB.image.repository=$(IMAGE_REGISTRY)/api-db \
		--set apiRedis.image.repository=$(IMAGE_REGISTRY)/api-redis \
		--set authServer.image.repository=$(IMAGE_REGISTRY)/auth-server \
		--set autoIdler.enabled=false \
		--set backupHandler.enabled=false \
		--set broker.image.repository=$(IMAGE_REGISTRY)/broker \
		--set sshkeyHandler.image.repository=$(IMAGE_REGISTRY)/api-sidecar-handler \
		--set insightsHandler.enabled=false \
		--set keycloak.image.repository=$(IMAGE_REGISTRY)/keycloak \
		--set keycloakDB.image.repository=$(IMAGE_REGISTRY)/keycloak-db \
		--set logs2notifications.image.repository=$(IMAGE_REGISTRY)/logs2notifications \
		--set logs2notifications.email.disabled=true \
		--set logs2notifications.microsoftteams.disabled=true \
		--set logs2notifications.rocketchat.disabled=true \
		--set logs2notifications.slack.disabled=true \
		--set logs2notifications.webhooks.disabled=true \
		--set ssh.image.repository=$(IMAGE_REGISTRY)/ssh \
		--set webhookHandler.image.repository=$(IMAGE_REGISTRY)/webhook-handler \
		--set webhooks2tasks.image.repository=$(IMAGE_REGISTRY)/webhooks2tasks \
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
		--set workflows.image.repository=$(IMAGE_REGISTRY)/workflows \
		--set keycloak.email.enabled=true \
		--set keycloak.email.settings.host=mailpit-smtp.mailpit.svc \
		--set keycloak.email.settings.port=25 \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshToken.service.ports.sshserver=2223') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set ssh.service.port=2020') \
		lagoon-core \
		./charts/lagoon-core

.PHONY: install-lagoon-remote
install-lagoon-remote: install-mariadb install-postgresql install-mongodb install-lagoon-core
	$(HELM) dependency build ./charts/lagoon-remote/
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		--values ./charts/lagoon-remote/ci/linter-values.yaml \
		--set "lagoon-build-deploy.enabled=false" \
		--set "dockerHost.registry=registry.$$($(KUBECTL) -n ingress-nginx get services ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io" \
		--set "dbaas-operator.mariadbProviders.development.environment=development" \
		--set "dbaas-operator.mariadbProviders.development.hostname=mariadb.mariadb.svc.cluster.local" \
		--set "dbaas-operator.mariadbProviders.development.password=$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')" \
		--set "dbaas-operator.mariadbProviders.development.port=3306" \
		--set "dbaas-operator.mariadbProviders.development.user=root" \
		--set "dbaas-operator.mariadbProviders.production.environment=production" \
		--set "dbaas-operator.mariadbProviders.production.hostname=mariadb.mariadb.svc.cluster.local" \
		--set "dbaas-operator.mariadbProviders.production.password=$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')" \
		--set "dbaas-operator.mariadbProviders.production.port=3306" \
		--set "dbaas-operator.mariadbProviders.production.user=root" \
		--set "dbaas-operator.postgresqlProviders.development.environment=development" \
		--set "dbaas-operator.postgresqlProviders.development.hostname=postgresql.postgresql.svc.cluster.local" \
		--set "dbaas-operator.postgresqlProviders.development.password=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')" \
		--set "dbaas-operator.postgresqlProviders.development.port=5432" \
		--set "dbaas-operator.postgresqlProviders.development.user=postgres" \
		--set "dbaas-operator.postgresqlProviders.production.environment=production" \
		--set "dbaas-operator.postgresqlProviders.production.hostname=postgresql.postgresql.svc.cluster.local" \
		--set "dbaas-operator.postgresqlProviders.production.password=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgres-password" | @base64d')" \
		--set "dbaas-operator.postgresqlProviders.production.port=5432" \
		--set "dbaas-operator.postgresqlProviders.production.user=postgres" \
		--set "dbaas-operator.mongodbProviders.development.environment=development" \
		--set "dbaas-operator.mongodbProviders.development.hostname=mongodb.mongodb.svc.cluster.local" \
		--set "dbaas-operator.mongodbProviders.development.password=$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')" \
		--set "dbaas-operator.mongodbProviders.development.port=27017" \
		--set "dbaas-operator.mongodbProviders.development.user=root" \
		--set "dbaas-operator.mongodbProviders.development.auth.mechanism=SCRAM-SHA-1" \
		--set "dbaas-operator.mongodbProviders.development.auth.source=admin" \
		--set "dbaas-operator.mongodbProviders.development.auth.tls=false" \
		--set "dbaas-operator.mongodbProviders.production.environment=production" \
		--set "dbaas-operator.mongodbProviders.production.hostname=mongodb.mongodb.svc.cluster.local" \
		--set "dbaas-operator.mongodbProviders.production.password=$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')" \
		--set "dbaas-operator.mongodbProviders.production.port=27017" \
		--set "dbaas-operator.mongodbProviders.production.user=root" \
		--set "dbaas-operator.mongodbProviders.production.auth.mechanism=SCRAM-SHA-1" \
		--set "dbaas-operator.mongodbProviders.production.auth.source=admin" \
		--set "dbaas-operator.mongodbProviders.production.auth.tls=false" \
		--set "sshCore.enaled=true" \
		--set "mxoutHost=mailpit-smtp.mailpit.svc.cluster.local" \
		$$([ $(IMAGE_TAG) ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.type=LoadBalancer') \
		$$([ $(LAGOON_SSH_PORTAL_LOADBALANCER) ] && echo '--set sshPortal.service.ports.sshserver=2222') \
		lagoon-remote \
		./charts/lagoon-remote
	$(KUBECTL) -n lagoon-core patch deployment lagoon-core-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"SSH_TOKEN_ENDPOINT_PORT","value":"'$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.spec.ports[0].port}')'"},{"name":"SSH_TOKEN_ENDPOINT","value":"'$$($(KUBECTL) -n lagoon get services lagoon-remote-ssh-portal -o jsonpath='{.status.loadBalancer.ingress[0].ip}')'"}]}]}}}}'

# The following target should only be called as a dependency of lagoon-remote
# Do not install without lagoon-core
#
.PHONY: install-lagoon-build-deploy
install-lagoon-build-deploy: install-lagoon-remote install-bulk-storageclass
	$(HELM) dependency build ./charts/lagoon-build-deploy/
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		--values ./charts/lagoon-build-deploy/ci/linter-values.yaml \
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
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set overrideBuildDeployImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG) ] && echo '--set image.tag=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY) ] && echo '--set image.repository=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY)') \
		$$([ $(BUILD_DEPLOY_CONTROLLER_ROOTLESS_BUILD_PODS) ] && echo '--set rootlessBuildPods=true') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD) ] && echo '--set lagoonFeatureFlagDefaultRootlessWorkload=$(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD)') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY) ] && echo '--set lagoonFeatureFlagDefaultIsolationNetworkPolicy=$(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY)') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_RWX_TO_RWO) ] && echo '--set lagoonFeatureFlagDefaultRWX2RWO=$(LAGOON_FEATURE_FLAG_DEFAULT_RWX_TO_RWO)') \
		lagoon-build-deploy \
		./charts/lagoon-build-deploy

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

.PHONY: install-lagoon
install-lagoon:  install-lagoon-core install-lagoon-remote

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
