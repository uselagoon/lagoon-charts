{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "lagoon-test.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lagoon-test.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lagoon-test.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lagoon-test.labels" -}}
helm.sh/chart: {{ include "lagoon-test.chart" . }}
{{ include "lagoon-test.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lagoon-test.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-test.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for the test suite.
*/}}
{{- define "lagoon-test.serviceAccountName" -}}
{{- default (include "lagoon-test.fullname" .) .Values.serviceAccount.name }}
{{- end }}




{{/*
Create a default fully qualified app name for local-git.
*/}}
{{- define "lagoon-test.localGit.fullname" -}}
{{- include "lagoon-test.fullname" . }}-local-git
{{- end }}

{{/*
Common labels local-git.
*/}}
{{- define "lagoon-test.localGit.labels" -}}
helm.sh/chart: {{ include "lagoon-test.chart" . }}
{{ include "lagoon-test.localGit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels local-git.
*/}}
{{- define "lagoon-test.localGit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lagoon-test.name" . }}
app.kubernetes.io/component: {{ include "lagoon-test.localGit.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
