{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "lagoon-remote.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lagoon-remote.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lagoon-remote.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lagoon-remote.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lagoon-remote.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use for dockerHost.
*/}}
{{- define "lagoon-remote.dockerHost.serviceAccountName" -}}
{{- default (include "lagoon-remote.dockerHost.fullname" .) .Values.dockerHost.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for dockerHost.
*/}}
{{- define "lagoon-remote.dockerHost.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-docker-host
{{- end }}

{{/*
Common labels dockerHost.
*/}}
{{- define "lagoon-remote.dockerHost.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.dockerHost.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels dockerHost.
*/}}
{{- define "lagoon-remote.dockerHost.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.dockerHost.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for storageCalculator.
*/}}
{{- define "lagoon-remote.storageCalculator.serviceAccountName" -}}
{{- default (include "lagoon-remote.storageCalculator.fullname" .) .Values.storageCalculator.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for storageCalculator.
*/}}
{{- define "lagoon-remote.storageCalculator.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-storage-calculator
{{- end }}

{{/*
Common labels storageCalculator.
*/}}
{{- define "lagoon-remote.storageCalculator.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.storageCalculator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels storageCalculator.
*/}}
{{- define "lagoon-remote.storageCalculator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.storageCalculator.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for kubernetesBuildDeploy.
*/}}
{{- define "lagoon-remote.kubernetesBuildDeploy.serviceAccountName" -}}
{{- default (include "lagoon-remote.kubernetesBuildDeploy.fullname" .) .Values.kubernetesBuildDeploy.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for kubernetesBuildDeploy.
*/}}
{{- define "lagoon-remote.kubernetesBuildDeploy.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-kubernetes-build-deploy
{{- end }}

{{/*
Common labels kubernetesBuildDeploy.
*/}}
{{- define "lagoon-remote.kubernetesBuildDeploy.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.kubernetesBuildDeploy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels kubernetesBuildDeploy.
*/}}
{{- define "lagoon-remote.kubernetesBuildDeploy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.kubernetesBuildDeploy.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use for sshCore.
*/}}
{{- define "lagoon-remote.sshCore.serviceAccountName" -}}
{{- default (include "lagoon-remote.sshCore.fullname" .) .Values.sshCore.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for sshCore.
*/}}
{{- define "lagoon-remote.sshCore.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-ssh-core
{{- end }}

{{/*
Common labels sshCore.
*/}}
{{- define "lagoon-remote.sshCore.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.sshCore.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels sshCore.
*/}}
{{- define "lagoon-remote.sshCore.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.sshCore.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create a definition that matches the fully qualified app name for the nats
subchart.
*/}}
{{- define "lagoon-remote.nats.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-{{ .Values.nats.nameOverride | default "nats" }}
{{- end }}



{{/*
Create the name of the service account to use for sshPortal.
*/}}
{{- define "lagoon-remote.sshPortal.serviceAccountName" -}}
{{- default (include "lagoon-remote.sshPortal.fullname" .) .Values.sshPortal.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for sshPortal.
*/}}
{{- define "lagoon-remote.sshPortal.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-ssh-portal
{{- end }}

{{/*
Common labels sshPortal.
*/}}
{{- define "lagoon-remote.sshPortal.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.sshPortal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels sshPortal.
*/}}
{{- define "lagoon-remote.sshPortal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.sshPortal.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use for insights-remote
*/}}
{{- define "lagoon-remote.insightsRemote.serviceAccountName" -}}
{{- default (include "lagoon-remote.insightsRemote.fullname" .) .Values.insightsRemote.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for insights-remote.
*/}}
{{- define "lagoon-remote.insightsRemote.fullname" -}}
{{- include "lagoon-remote.fullname" . }}-insights-remote
{{- end }}

{{/*
Common labels insights-remote
*/}}
{{- define "lagoon-remote.insightsRemote.labels" -}}
helm.sh/chart: {{ include "lagoon-remote.chart" . }}
{{ include "lagoon-remote.insightsRemote.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels insightsRemote
*/}}
{{- define "lagoon-remote.insightsRemote.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-remote.name" . }}
app.kubernetes.io/component: {{ include "lagoon-remote.insightsRemote.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
