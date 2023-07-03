{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "lagoon-docker-host.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lagoon-docker-host.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lagoon-docker-host.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lagoon-docker-host.labels" -}}
helm.sh/chart: {{ include "lagoon-docker-host.chart" . }}
{{ include "lagoon-docker-host.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lagoon-docker-host.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-docker-host.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use for dockerHost.
*/}}
{{- define "lagoon-docker-host.dockerHost.serviceAccountName" -}}
{{- default (include "lagoon-docker-host.dockerHost.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Create a default fully qualified app name for dockerHost.
*/}}
{{- define "lagoon-docker-host.dockerHost.fullname" -}}
{{- include "lagoon-docker-host.fullname" . }}-docker-host
{{- end }}

{{/*
Common labels dockerHost.
*/}}
{{- define "lagoon-docker-host.dockerHost.labels" -}}
helm.sh/chart: {{ include "lagoon-docker-host.chart" . }}
{{ include "lagoon-docker-host.dockerHost.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels dockerHost.
*/}}
{{- define "lagoon-docker-host.dockerHost.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-docker-host.name" . }}
app.kubernetes.io/component: {{ include "lagoon-docker-host.dockerHost.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

