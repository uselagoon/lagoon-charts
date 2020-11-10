.PHONY: fill-test-ci-values
fill-test-ci-values: install-ingress install-registry install-lagoon-core install-lagoon-remote
	export ingressIP="$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')" \
		&& export keycloakAuthServerClientSecret="$$(kubectl -n lagoon get secret lagoon-core-keycloak -o json | jq -r '.data.KEYCLOAK_AUTH_SERVER_CLIENT_SECRET | @base64d')" \
		&& export routeSuffixHTTP="$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export routeSuffixHTTPS="$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		&& export token="$$(kubectl -n lagoon get secret -o json | jq -r '.items[] | select(.metadata.name | match("lagoon-build-deploy-token")) | .data.token | @base64d')" \
		&& valueTemplate=charts/lagoon-test/ci/linter-values.yaml \
		&& envsubst < $$valueTemplate.tpl > $$valueTemplate

.PHONY: install-ingress
install-ingress:
	helm upgrade \
		--install \
		--create-namespace \
		--namespace ingress-nginx \
		--wait \
		--timeout 15m \
		--set controller.service.type=NodePort \
		--set controller.service.nodePorts.http=32080 \
		--set controller.service.nodePorts.https=32443 \
		--set controller.config.proxy-body-size=100m \
		ingress-nginx \
		ingress-nginx/ingress-nginx

.PHONY: install-registry
install-registry:
	helm upgrade \
		--install \
		--create-namespace \
		--namespace registry \
		--wait \
		--timeout 15m \
		--set expose.tls.enabled=false \
		--set "expose.ingress.annotations.kubernetes\.io\/ingress\.class=nginx" \
		--set "expose.ingress.hosts.core=registry.$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io" \
		--set "externalURL=http://registry.$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set chartmuseum.enabled=false \
		--set clair.enabled=false \
		--set notary.enabled=false \
		--set trivy.enabled=false \
		registry \
		harbor/harbor

.PHONY: install-lagoon-core
install-lagoon-core:
	helm upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout 15m \
		--values ./charts/lagoon-core/ci/linter-values.yaml \
		--set autoIdler.enabled=false \
		--set logs2email.enabled=false \
		--set logs2microsoftteams.enabled=false \
		--set logs2rocketchat.enabled=false \
		--set logs2slack.enabled=false \
		--set logsDBCurator.enabled=false \
		--set webhooks2tasks.enabled=false \
		--set webhookHandler.enabled=false \
		--set ui.enabled=false \
		--set "registry=registry.$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32443" \
		--set "lagoonAPIURL=http://localhost:7070/graphql" \
		--set "keycloakAPIURL=http://localhost:8080/auth" \
		--set "harborURL=http://registry.$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		--set "harborAdminPassword=Harbor12345" \
		--set storageCalculator.enabled=false \
		--set sshPortal.enabled=false \
		lagoon-core \
		./charts/lagoon-core

.PHONY: install-lagoon-remote
install-lagoon-remote: install-lagoon-core
	helm upgrade \
		--install \
		--create-namespace \
		--namespace lagoon \
		--wait \
		--timeout 15m \
		--values ./charts/lagoon-remote/ci/linter-values.yaml \
		--set "rabbitMQPassword=$$(kubectl -n lagoon get secret lagoon-core-broker -o json | jq -r '.data.RABBITMQ_PASSWORD | @base64d')" \
		--set "dockerHost.registry=registry.$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}').nip.io:32080" \
		lagoon-remote \
		./charts/lagoon-remote
