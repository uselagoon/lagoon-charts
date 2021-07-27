{{/* vim: set filetype=mustache: */}}
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
Selector labels auto-idler.
*/}}
{{- define "lagoon-core.autoIdler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.autoIdler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for storage-calculator.
*/}}
{{- define "lagoon-core.storageCalculator.fullname" -}}
{{- include "lagoon-core.fullname" . }}-storage-calculator
{{- end }}

{{/*
Common labels storage-calculator.
*/}}
{{- define "lagoon-core.storageCalculator.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.storageCalculator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels storage-calculator.
*/}}
{{- define "lagoon-core.storageCalculator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.storageCalculator.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for logs2slack.
*/}}
{{- define "lagoon-core.logs2slack.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2slack
{{- end }}

{{/*
Common labels logs2slack.
*/}}
{{- define "lagoon-core.logs2slack.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2slack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2slack.
*/}}
{{- define "lagoon-core.logs2slack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2slack.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for logs2webhook.
*/}}
{{- define "lagoon-core.logs2webhook.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2webhook
{{- end }}

{{/*
Common labels logs2webhook.
*/}}
{{- define "lagoon-core.logs2webhook.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2webhook.
*/}}
{{- define "lagoon-core.logs2webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2webhook.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for logs2microsoftteams.
*/}}
{{- define "lagoon-core.logs2microsoftteams.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2microsoftteams
{{- end }}

{{/*
Common labels logs2microsoftteams.
*/}}
{{- define "lagoon-core.logs2microsoftteams.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2microsoftteams.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2microsoftteams.
*/}}
{{- define "lagoon-core.logs2microsoftteams.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2microsoftteams.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for logs2rocketchat.
*/}}
{{- define "lagoon-core.logs2rocketchat.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2rocketchat
{{- end }}

{{/*
Common labels logs2rocketchat.
*/}}
{{- define "lagoon-core.logs2rocketchat.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2rocketchat.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2rocketchat.
*/}}
{{- define "lagoon-core.logs2rocketchat.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2rocketchat.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for logs2email.
*/}}
{{- define "lagoon-core.logs2email.fullname" -}}
{{- include "lagoon-core.fullname" . }}-logs2email
{{- end }}

{{/*
Common labels logs2email.
*/}}
{{- define "lagoon-core.logs2email.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.logs2email.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels logs2email.
*/}}
{{- define "lagoon-core.logs2email.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.logs2email.fullname" . }}
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
Create the name of the service account to use for ssh-portal.
*/}}
{{- define "lagoon-core.sshPortal.serviceAccountName" -}}
{{- default (include "lagoon-core.sshPortal.fullname" .) .Values.sshPortal.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for ssh-portal.
*/}}
{{- define "lagoon-core.sshPortal.fullname" -}}
{{- include "lagoon-core.fullname" . }}-ssh-portal
{{- end }}

{{/*
Common labels ssh-portal.
*/}}
{{- define "lagoon-core.sshPortal.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.sshPortal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ssh-portal.
*/}}
{{- define "lagoon-core.sshPortal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.sshPortal.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a default fully qualified app name for controllerhandler.
*/}}
{{- define "lagoon-core.controllerhandler.fullname" -}}
{{- include "lagoon-core.fullname" . }}-controllerhandler
{{- end }}

{{/*
Common labels controllerhandler.
*/}}
{{- define "lagoon-core.controllerhandler.labels" -}}
helm.sh/chart: {{ include "lagoon-core.chart" . }}
{{ include "lagoon-core.controllerhandler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels controllerhandler.
*/}}
{{- define "lagoon-core.controllerhandler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-core.name" . }}
app.kubernetes.io/component: {{ include "lagoon-core.controllerhandler.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
