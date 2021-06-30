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

TIMEOUT = 30m
HELM = helm
KUBECTL = kubectl
JQ = jq

.PHONY: fill-test-ci-values
fill-test-ci-values:
	export ingressIP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}')" \
		&& export keycloakAuthServerClientSecret="$$($(KUBECTL) -n lagoon get secret lagoon-core-keycloak -o json | $(JQ) -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export routeSuffixHTTPS="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export token="$$($(KUBECTL) -n lagoon get secret -o json | $(JQ) -r '.items[] | select(.metadata.name | match("lagoon-build-deploy-token")) | .data.token | @base64d')" \
		&& export $$([ $(IMAGE_TAG) ] && echo imageTag='$(IMAGE_TAG)' || echo imageTag='latest') \
		&& export webhookHandler="lagoon-core-webhook-handler" \
		&& export tests='$(TESTS)' imageRegistry='$(IMAGE_REGISTRY)' \
		&& valueTemplate=charts/lagoon-test/ci/linter-values.yaml \
		&& envsubst < $$valueTemplate.tpl > $$valueTemplate

ifneq ($(SKIP_ALL_DEPS),true)
ifneq ($(SKIP_INSTALL_REGISTRY),true)
fill-test-ci-values: install-registry
endif
fill-test-ci-values: install-ingress install-lagoon-core install-lagoon-remote install-nfs-server-provisioner
endif

.PHONY: install-ingress
install-ingress:
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace ingress-nginx \
		--wait \
		--timeout $(TIMEOUT) \
		--set controller.service.type=NodePort \
		--set controller.service.nodePorts.http=32080 \
		--set controller.service.nodePorts.https=32443 \
		--set controller.config.proxy-body-size=100m \
		--set controller.admissionWebhooks.enabled=false \
		--version=3.31.0 \
		ingress-nginx \
		ingress-nginx/ingress-nginx

.PHONY: install-registry
install-registry: install-ingress
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace registry \
		--wait \
		--timeout $(TIMEOUT) \
		--set expose.tls.enabled=false \
		--set "expose.ingress.annotations.kubernetes\.io\/ingress\.class=nginx" \
		--set "expose.ingress.hosts.core=registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		--set "externalURL=http://registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set chartmuseum.enabled=false \
		--set clair.enabled=false \
		--set notary.enabled=false \
		--set trivy.enabled=false \
		--version=1.5.5 \
		registry \
		harbor/harbor

.PHONY: install-nfs-server-provisioner
install-nfs-server-provisioner:
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace nfs-server-provisioner \
		--wait \
		--timeout $(TIMEOUT) \
		--set storageClass.name=bulk \
		--version=1.1.3 \
		nfs-server-provisioner \
		stable/nfs-server-provisioner

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
		--version=9.3.13 \
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
		$$($(KUBECTL) get ns postgresql > /dev/null 2>&1 && echo --set postgresqlPassword=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgresql-password" | @base64d')) \
		--version=10.4.8 \
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
		--version=10.16.4 \
		mongodb \
		bitnami/mongodb

.PHONY: install-lagoon-core
install-lagoon-core:
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		--values ./charts/lagoon-core/ci/linter-values.yaml \
		$$([ $(IMAGE_TAG) ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set overwriteKubectlBuildDeployDindImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		--set "harborAdminPassword=Harbor12345" \
		--set "harborURL=http://registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set "keycloakAPIURL=http://localhost:8080/auth" \
		--set "lagoonAPIURL=http://localhost:7070/graphql" \
		--set "registry=registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set api.image.repository=$(IMAGE_REGISTRY)/api \
		--set apiDB.image.repository=$(IMAGE_REGISTRY)/api-db \
		--set apiRedis.image.repository=$(IMAGE_REGISTRY)/api-redis \
		--set authServer.image.repository=$(IMAGE_REGISTRY)/auth-server \
		--set autoIdler.enabled=false \
		--set backupHandler.enabled=false \
		--set broker.image.repository=$(IMAGE_REGISTRY)/broker \
		--set controllerhandler.image.repository=$(IMAGE_REGISTRY)/controllerhandler \
		--set drushAlias.image.repository=$(IMAGE_REGISTRY)/drush-alias \
		--set keycloak.image.repository=$(IMAGE_REGISTRY)/keycloak \
		--set keycloakDB.image.repository=$(IMAGE_REGISTRY)/keycloak-db \
		--set logs2email.enabled=false \
		--set logs2microsoftteams.enabled=false \
		--set logs2rocketchat.enabled=false \
		--set logs2slack.enabled=false \
		--set logs2webhook.enabled=false \
		--set logsDBCurator.enabled=false \
		--set ssh.image.repository=$(IMAGE_REGISTRY)/ssh \
		--set sshPortal.enabled=false \
		--set storageCalculator.enabled=false \
		--set ui.image.repository=$(IMAGE_REGISTRY)/ui \
		--set webhookHandler.image.repository=$(IMAGE_REGISTRY)/webhook-handler \
		--set webhooks2tasks.image.repository=$(IMAGE_REGISTRY)/webhooks2tasks \
		lagoon-core \
		./charts/lagoon-core

.PHONY: install-lagoon-remote
install-lagoon-remote: install-lagoon-core install-mariadb install-postgresql install-mongodb
	$(HELM) dependency build ./charts/lagoon-remote/
	$(HELM) upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout $(TIMEOUT) \
		--values ./charts/lagoon-remote/ci/linter-values.yaml \
		--set dockerHost.image.repository=$(IMAGE_REGISTRY)/docker-host \
		--set "lagoon-build-deploy.rabbitMQPassword=$$($(KUBECTL) -n lagoon get secret lagoon-core-broker -o json | $(JQ) -r '.data.RABBITMQ_PASSWORD | @base64d')" \
		--set "dockerHost.registry=registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set "dbaas-operator.mariadbProviders.development.environment=development" \
		--set "dbaas-operator.mariadbProviders.development.hostname=mariadb.mariadb.svc.cluster.local" \
		--set "dbaas-operator.mariadbProviders.development.password=$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')" \
		--set "dbaas-operator.mariadbProviders.development.port=3306" \
		--set "dbaas-operator.mariadbProviders.development.user=root" \
		--set "dbaas-operator.postgresqlProviders.development.environment=development" \
		--set "dbaas-operator.postgresqlProviders.development.hostname=postgresql.postgresql.svc.cluster.local" \
		--set "dbaas-operator.postgresqlProviders.development.password=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgresql-password" | @base64d')" \
		--set "dbaas-operator.postgresqlProviders.development.port=5432" \
		--set "dbaas-operator.postgresqlProviders.development.user=postgres" \
		--set "dbaas-operator.mongodbProviders.development.environment=development" \
		--set "dbaas-operator.mongodbProviders.development.hostname=mongodb.mongodb.svc.cluster.local" \
		--set "dbaas-operator.mongodbProviders.development.password=$$($(KUBECTL) get secret --namespace mongodb mongodb -o json | $(JQ) -r '.data."mongodb-root-password" | @base64d')" \
		--set "dbaas-operator.mongodbProviders.development.port=27017" \
		--set "dbaas-operator.mongodbProviders.development.user=root" \
		--set "dbaas-operator.mongodbProviders.development.auth.mechanism=SCRAM-SHA-1" \
		--set "dbaas-operator.mongodbProviders.development.auth.source=admin" \
		--set "dbaas-operator.mongodbProviders.development.auth.tls=false" \
		$$([ $(IMAGE_TAG) ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set lagoon-build-deploy.overrideBuildDeployImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG) ] && echo '--set lagoon-build-deploy.image.tag=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY) ] && echo '--set lagoon-build-deploy.image.repository=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGE_REPOSITORY)') \
		$$([ $(BUILD_DEPLOY_CONTROLLER_ROOTLESS_BUILD_PODS) ] && echo '--set lagoon-build-deploy.rootlessBuildPods=true') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD) ] && echo '--set lagoon-build-deploy.lagoonFeatureFlagDefaultRootlessWorkload=$(LAGOON_FEATURE_FLAG_DEFAULT_ROOTLESS_WORKLOAD)') \
		$$([ $(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY) ] && echo '--set lagoon-build-deploy.lagoonFeatureFlagDefaultRootlessWorkload=$(LAGOON_FEATURE_FLAG_DEFAULT_ISOLATION_NETWORK_POLICY)') \
		lagoon-remote \
		./charts/lagoon-remote

#
# The following targets facilitate local development only and aren't used in CI.
#

.PHONY: create-kind-cluster
create-kind-cluster:
	docker network inspect kind >/dev/null || docker network create kind \
		&& export KIND_NODE_IP=$$(docker run --network kind --rm alpine ip -o addr show eth0 | sed -nE 's/.* ([0-9.]{7,})\/.*/\1/p') \
		&& envsubst < test-suite.kind-config.yaml.tpl > test-suite.kind-config.yaml \
		&& envsubst < test-suite.kind-config.calico.yaml.tpl > test-suite.kind-config.calico.yaml
ifeq ($(USE_CALICO_CNI),true)
	kind create cluster --wait=60s --config=test-suite.kind-config.calico.yaml \
		&& kubectl apply -f ./ci/calico/tigera-operator.yaml \
		&& kubectl apply -f ./ci/calico/custom-resources.yaml

.PHONY: install-calico
install-calico:
	$(KUBECTL) apply -f ./ci/calico/tigera-operator.yaml \
		&& $(KUBECTL) apply -f ./ci/calico/custom-resources.yaml

# add dependencies to ensure calico gets installed in the correct order
install-ingress: install-calico
install-registry: install-calico
install-nfs-server-provisioner: install-calico
install-mariadb: install-calico
install-postgresql: install-calico
install-mongodb: install-calico
install-lagoon-core: install-calico
install-lagoon-remote: install-calico
else
	kind create cluster --wait=60s --config=test-suite.kind-config.yaml
endif

.PHONY: install-test-cluster
install-test-cluster: install-ingress install-registry install-nfs-server-provisioner install-mariadb install-postgresql install-mongodb

.PHONY: install-lagoon
install-lagoon:  install-lagoon-core install-lagoon-remote

.PHONY: get-admin-creds
get-admin-creds:
	echo "\nGraphQL admin token: \n$$(docker run \
		-e JWTSECRET="$$($(KUBECTL) get secret -n lagoon lagoon-core-jwtsecret -o jsonpath="{.data.JWTSECRET}" | base64 --decode)" \
		-e JWTAUDIENCE=api.dev \
		-e JWTUSER=localadmin \
		uselagoon/tests \
		python3 /ansible/tasks/api/admin_token.py)" \
	&& echo "Keycloak admin password: " \
	&& $(KUBECTL) get secret -n lagoon lagoon-core-keycloak -o jsonpath="{.data.KEYCLOAK_ADMIN_PASSWORD}" | base64 --decode \
	&& echo "\nKeycloak password for lagoonadmin user: " \
	&& $(KUBECTL) get secret -n lagoon lagoon-core-keycloak -o jsonpath="{.data.KEYCLOAK_LAGOON_ADMIN_PASSWORD}" | base64 --decode \
	&& echo "\n"

.PHONY: pf-keycloak pf-api pf-ssh pf-ui
pf-keycloak:
	$(KUBECTL) port-forward -n lagoon svc/lagoon-core-keycloak 8080 2>/dev/null &
pf-api:
	$(KUBECTL) port-forward -n lagoon svc/lagoon-core-api 7070:80 2>/dev/null &
pf-ssh:
	$(KUBECTL) port-forward -n lagoon svc/lagoon-core-ssh 2020 2>/dev/null &
pf-ui:
	$(KUBECTL) port-forward -n lagoon svc/lagoon-core-ui 6060:3000 2>/dev/null &

.PHONY: port-forwards
port-forwards: pf-keycloak pf-api pf-ssh pf-ui

.PHONY: run-tests
run-tests:
	$(HELM) test --namespace lagoon --timeout 30m lagoon-test
