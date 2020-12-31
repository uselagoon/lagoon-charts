TESTS = [features-kubernetes]
# if IMAGE_TAG is not set, it will fall back to the version set in the CI
# values file, then to the chart default.
IMAGE_TAG =
# if IMAGE_REGISTRY is not set, it will fall back to the version set in the
# chart values files. This only affects lagoon-core, lagoon-remote, and the
# fill-test-ci-values target.
IMAGE_REGISTRY = uselagoon
# if OVERRIDE_BUILD_DEPLOY_DIND_IMAGE is not set, it will fall back to the
# controller default (uselagoon/kubectl-build-deploy-dind:latest).
OVERRIDE_BUILD_DEPLOY_DIND_IMAGE =
# Overrides the image tag for amazeeio/lagoon-builddeploy whose default is
# the lagoon-build-deploy chart appVersion.
OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG =
TIMEOUT = 30m
HELM = helm
KUBECTL = kubectl
JQ = jq

.PHONY: fill-test-ci-values
fill-test-ci-values: install-ingress install-registry install-lagoon-core install-lagoon-remote install-nfs-server-provisioner
	export ingressIP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}')" \
		&& export keycloakAuthServerClientSecret="$$($(KUBECTL) -n lagoon get secret lagoon-core-keycloak -o json | $(JQ) -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export routeSuffixHTTPS="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export token="$$($(KUBECTL) -n lagoon get secret -o json | $(JQ) -r '.items[] | select(.metadata.name | match("lagoon-build-deploy-token")) | .data.token | @base64d')" \
		&& export $$([ $(IMAGE_TAG) ] && echo imageTag='$(IMAGE_TAG)' || echo imageTag='latest') \
		&& export tests='$(TESTS)' imageRegistry='$(IMAGE_REGISTRY)' \
		&& valueTemplate=charts/lagoon-test/ci/linter-values.yaml \
		&& envsubst < $$valueTemplate.tpl > $$valueTemplate

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
		--version=3.15.2 \
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
		--version=1.5.2 \
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
		--version=9.1.4 \
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
		--version=10.2.0 \
		postgresql \
		bitnami/postgresql

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
		--set "registry=registry.$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32443" \
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
		--set logsDBCurator.enabled=false \
		--set ssh.image.repository=$(IMAGE_REGISTRY)/ssh \
		--set sshPortal.enabled=false \
		--set storageCalculator.enabled=false \
		--set ui.enabled=false \
		--set webhookHandler.image.repository=$(IMAGE_REGISTRY)/webhook-handler \
		--set webhooks2tasks.image.repository=$(IMAGE_REGISTRY)/webhooks2tasks \
		lagoon-core \
		./charts/lagoon-core

.PHONY: install-lagoon-remote
install-lagoon-remote: install-lagoon-core install-mariadb install-postgresql
	$(HELM) dependency update ./charts/lagoon-remote/
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
		--set "dbaasOperator.mariadbProviders.development.environment=development" \
		--set "dbaasOperator.mariadbProviders.development.hostname=mariadb.mariadb.svc.cluster.local" \
		--set "dbaasOperator.mariadbProviders.development.password=$$($(KUBECTL) get secret --namespace mariadb mariadb -o json | $(JQ) -r '.data."mariadb-root-password" | @base64d')" \
		--set "dbaasOperator.mariadbProviders.development.port=3306" \
		--set "dbaasOperator.mariadbProviders.development.user=root" \
		--set "dbaasOperator.postgresqlProviders.development.environment=development" \
		--set "dbaasOperator.postgresqlProviders.development.hostname=postgresql.postgresql.svc.cluster.local" \
		--set "dbaasOperator.postgresqlProviders.development.password=$$($(KUBECTL) get secret --namespace postgresql postgresql -o json | $(JQ) -r '.data."postgresql-password" | @base64d')" \
		--set "dbaasOperator.postgresqlProviders.development.port=5432" \
		--set "dbaasOperator.postgresqlProviders.development.user=postgres" \
		$$([ $(IMAGE_TAG) ] && echo '--set imageTag=$(IMAGE_TAG)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set lagoon-build-deploy.overrideBuildDeployDindImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE) ] && echo '--set lagoon-build-deploy.overrideBuildDeployImage=$(OVERRIDE_BUILD_DEPLOY_DIND_IMAGE)') \
		$$([ $(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG) ] && echo '--set lagoon-build-deploy.image.tag=$(OVERRIDE_BUILD_DEPLOY_CONTROLLER_IMAGETAG)') \
		lagoon-remote \
		./charts/lagoon-remote

.PHONY: create-kind-cluster
create-kind-cluster:
	docker network inspect kind >/dev/null || docker network create kind \
		&& export KIND_NODE_IP=$$(docker run --network kind --rm alpine ip -o addr show eth0 | sed -nE 's/.* ([0-9.]{7,})\/.*/\1/p') \
		&& envsubst < test-suite.kind-config.yaml.tpl > test-suite.kind-config.yaml \
		&& kind create cluster --config=test-suite.kind-config.yaml

.PHONY: install-test-cluster
install-test-cluster: install-ingress install-registry install-nfs-server-provisioner install-mariadb install-postgresql

.PHONY: install-lagoon
install-lagoon:  install-lagoon-core install-lagoon-remote

## install-tests here uses the same logic as the fill-ci-values above,
## but doesn't re-run all the cluster and lagoon building steps
.PHONY: install-tests
install-tests:
	export ingressIP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}')" \
		&& export keycloakAuthServerClientSecret="$$($(KUBECTL) -n lagoon get secret lagoon-core-keycloak -o json | $(JQ) -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export routeSuffixHTTPS="$$($(KUBECTL) get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export token="$$($(KUBECTL) -n lagoon get secret -o json | $(JQ) -r '.items[] | select(.metadata.name | match("lagoon-build-deploy-token")) | .data.token | @base64d')" \
		&& export $$([ $(IMAGE_TAG) ] && echo imageTag='$(IMAGE_TAG)' || echo imageTag='latest') \
		&& export tests='$(TESTS)' imageRegistry='$(IMAGE_REGISTRY)' \
		&& valueTemplate=charts/lagoon-test/ci/linter-values.yaml \
		&& envsubst < $$valueTemplate.tpl > $$valueTemplate \
		&& $(HELM) upgrade \
			--install \
			--namespace lagoon \
			--wait \
			--timeout 30m \
			--values ./charts/lagoon-test/ci/linter-values.yaml \
			lagoon-test \
			./charts/lagoon-test

.PHONY: run-tests
run-tests:
	$(HELM) test --namespace lagoon --timeout 30m lagoon-test
