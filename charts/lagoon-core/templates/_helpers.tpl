{{/*
Expand the name of the chart.
*/}}
{{- define "lagoon-core.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lagoon-core.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lagoon-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lagoon-core.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lagoon-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for api.
*/}}
{{- define "lagoon-core.api.fullname" -}}
{{- include "lagoon-core.fullname" . }}-api
{{- end }}

{{/*
Common labels api
*/}}
{{- define "lagoon-core.api.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels api
*/}}
{{- define "lagoon-core.api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.api.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for api-migratedb-job.
*/}}
{{- define "lagoon-core.apiMigrateDB.fullname" -}}
{{- include "lagoon-core.fullname" . }}-api-migratedb
{{- end }}


{{/*
Create a default fully qualified app name for api-db.
*/}}
{{- define "lagoon-core.apiDB.fullname" -}}
{{- include "lagoon-core.fullname" . }}-api-db
{{- end }}

{{/*
Common labels api-db
*/}}
{{- define "lagoon-core.apiDB.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.apiDB.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels api-db
*/}}
{{- define "lagoon-core.apiDB.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.apiDB.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for api-redis.
*/}}
{{- define "lagoon-core.apiRedis.fullname" -}}
{{- include "lagoon-core.fullname" . }}-api-redis
{{- end }}

{{/*
Common labels api-redis
*/}}
{{- define "lagoon-core.apiRedis.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.apiRedis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels api-redis
*/}}
{{- define "lagoon-core.apiRedis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.apiRedis.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for keycloak.
*/}}
{{- define "lagoon-core.keycloak.fullname" -}}
{{- include "lagoon-core.fullname" . }}-keycloak
{{- end }}

{{/*
Common labels keycloak
*/}}
{{- define "lagoon-core.keycloak.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.keycloak.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels keycloak
*/}}
{{- define "lagoon-core.keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.keycloak.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for keycloak-db.
*/}}
{{- define "lagoon-core.keycloakDB.fullname" -}}
{{- include "lagoon-core.fullname" . }}-keycloak-db
{{- end }}

{{/*
Common labels keycloak-db
*/}}
{{- define "lagoon-core.keycloakDB.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.keycloakDB.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels keycloak-db
*/}}
{{- define "lagoon-core.keycloakDB.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.keycloakDB.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use for broker.
*/}}
{{- define "lagoon-core.broker.serviceAccountName" -}}
{{- default (include "lagoon-core.broker.fullname" .) .Values.broker.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for broker.
*/}}
{{- define "lagoon-core.broker.fullname" -}}
{{- include "lagoon-core.fullname" . }}-broker
{{- end }}

{{/*
Common labels broker
*/}}
{{- define "lagoon-core.broker.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.broker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels broker
*/}}
{{- define "lagoon-core.broker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.broker.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for auth-server.
*/}}
{{- define "lagoon-core.authServer.fullname" -}}
{{- include "lagoon-core.fullname" . }}-auth-server
{{- end }}

{{/*
Common labels auth-server
*/}}
{{- define "lagoon-core.authServer.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.authServer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels auth-server
*/}}
{{- define "lagoon-core.authServer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.authServer.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for webhooks2tasks.
*/}}
{{- define "lagoon-core.webhooks2tasks.fullname" -}}
{{- include "lagoon-core.fullname" . }}-webhooks2tasks
{{- end }}

{{/*
Common labels webhooks2tasks
*/}}
{{- define "lagoon-core.webhooks2tasks.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.webhooks2tasks.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels webhooks2tasks
*/}}
{{- define "lagoon-core.webhooks2tasks.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.webhooks2tasks.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for webhookHandler.
*/}}
{{- define "lagoon-core.webhookHandler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-webhook-handler
{{- end }}

{{/*
Common labels webhookHandler
*/}}
{{- define "lagoon-core.webhookHandler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.webhookHandler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels webhookHandler
*/}}
{{- define "lagoon-core.webhookHandler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.webhookHandler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for ui.
*/}}
{{- define "lagoon-core.ui.fullname" -}}
{{- include "lagoon-core.fullname" . }}-ui
{{- end }}

{{/*
Common labels ui
*/}}
{{- define "lagoon-core.ui.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ui
*/}}
{{- define "lagoon-core.ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.ui.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for backup-handler.
*/}}
{{- define "lagoon-core.backupHandler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-backup-handler
{{- end }}

{{/*
Common labels backup-handler.
*/}}
{{- define "lagoon-core.backupHandler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.backupHandler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels backup-handler.
*/}}
{{- define "lagoon-core.backupHandler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.backupHandler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for actions-handler.
*/}}
{{- define "lagoon-core.actionsHandler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-actions-handler
{{- end }}

{{/*
Common labels actions-handler.
*/}}
{{- define "lagoon-core.actionsHandler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.actionsHandler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels actions-handler.
*/}}
{{- define "lagoon-core.actionsHandler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.actionsHandler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for auto-idler.
*/}}
{{- define "lagoon-core.autoIdler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-auto-idler
{{- end }}

{{/*
Common labels auto-idler.
*/}}
{{- define "lagoon-core.autoIdler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.autoIdler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Create a default fully qualified app name for insights-handler.
*/}}
{{- define "lagoon-core.insightsHandler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-insights-handler
{{- end }}

{{/*
Common labels insights-handler.
*/}}
{{- define "lagoon-core.insightsHandler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.insightsHandler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels insights-handler.
*/}}
{{- define "lagoon-core.insightsHandler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.insightsHandler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for logs2notifications.
*/}}
{{- define "lagoon-core.logs2notifications.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2notifications
{{- end }}

{{/*
Common labels logs2notifications.
*/}}
{{- define "lagoon-core.logs2notifications.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2notifications.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2notifications.
*/}}
{{- define "lagoon-core.logs2notifications.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2notifications.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create a default fully qualified app name for drush-alias.
*/}}
{{- define "lagoon-core.drushAlias.fullname" -}}
{{- include "lagoon-core.fullname" . }}-drush-alias
{{- end }}

{{/*
Common labels drush-alias.
*/}}
{{- define "lagoon-core.drushAlias.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.drushAlias.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels drush-alias.
*/}}
{{- define "lagoon-core.drushAlias.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.drushAlias.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name for ssh.
*/}}
{{- define "lagoon-core.ssh.fullname" -}}
{{- include "lagoon-core.fullname" . }}-ssh
{{- end }}

{{/*
Common labels ssh.
*/}}
{{- define "lagoon-core.ssh.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.ssh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ssh.
*/}}
{{- define "lagoon-core.ssh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.ssh.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
--- WORKFLOWS ---
*/}}
{{/*
Create a default fully qualified app name for workflows.
*/}}
{{- define "lagoon-core.workflows.fullname" -}}
{{- include "lagoon-core.fullname" . }}-workflows
{{- end }}

{{/*
Common labels workflows
*/}}
{{- define "lagoon-core.workflows.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.workflows.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels workflows
*/}}
{{- define "lagoon-core.workflows.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.workflows.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for the nats subchart.
*/}}
{{- define "lagoon-core.nats.fullname" -}}
{{- include "lagoon-core.fullname" . }}-nats
{{- end }}



{{/*
Create a default fully qualified app name for ssh-portal-api.
*/}}
{{- define "lagoon-core.sshPortalAPI.fullname" -}}
{{- include "lagoon-core.fullname" . }}-ssh-portal-api
{{- end }}

{{/*
Common labels ssh-portal-api.
*/}}
{{- define "lagoon-core.sshPortalAPI.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.sshPortalAPI.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ssh-portal-api.
*/}}
{{- define "lagoon-core.sshPortalAPI.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.sshPortalAPI.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for opensearch-sync.
*/}}
{{- define "lagoon-core.opensearchSync.fullname" -}}
{{- include "lagoon-core.fullname" . }}-opensearch-sync
{{- end }}

{{/*
Common labels opensearch-sync.
*/}}
{{- define "lagoon-core.opensearchSync.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.opensearchSync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels opensearch-sync.
*/}}
{{- define "lagoon-core.opensearchSync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.opensearchSync.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for ssh-token.
*/}}
{{- define "lagoon-core.sshToken.fullname" -}}
{{- include "lagoon-core.fullname" . }}-ssh-token
{{- end }}

{{/*
Common labels ssh-token.
*/}}
{{- define "lagoon-core.sshToken.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.sshToken.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ssh-token.
*/}}
{{- define "lagoon-core.sshToken.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.sshToken.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get HorizontalPodAutoscaler API Version - can be removed once Kubernetes 1.23 is the minimum
*/}}
{{- define "lagoon-core.hpa.apiVersion" -}}
  {{- if (.Capabilities.APIVersions.Has "autoscaling/v2") -}}
    autoscaling/v2
  {{- else -}}
    autoscaling/v2beta2
  {{- end -}}
{{- end -}}
