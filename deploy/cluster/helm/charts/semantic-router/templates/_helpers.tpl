{{/*
Expand the name of the chart.
*/}}
{{- define "semantic-router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "semantic-router.fullname" -}}
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
{{- define "semantic-router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "semantic-router.labels" -}}
helm.sh/chart: {{ include "semantic-router.chart" . }}
{{ include "semantic-router.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "semantic-router.selectorLabels" -}}
app.kubernetes.io/name: {{ include "semantic-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ExtProc labels
*/}}
{{- define "semantic-router.extproc.labels" -}}
{{ include "semantic-router.labels" . }}
app.kubernetes.io/component: extproc
{{- end }}

{{/*
ExtProc selector labels
*/}}
{{- define "semantic-router.extproc.selectorLabels" -}}
{{ include "semantic-router.selectorLabels" . }}
app.kubernetes.io/component: extproc
{{- end }}

{{/*
Envoy labels
*/}}
{{- define "semantic-router.envoy.labels" -}}
{{ include "semantic-router.labels" . }}
app.kubernetes.io/component: envoy
{{- end }}

{{/*
Envoy selector labels
*/}}
{{- define "semantic-router.envoy.selectorLabels" -}}
{{ include "semantic-router.selectorLabels" . }}
app.kubernetes.io/component: envoy
{{- end }}

{{/*
Dashboard labels
*/}}
{{- define "semantic-router.dashboard.labels" -}}
{{ include "semantic-router.labels" . }}
app.kubernetes.io/component: dashboard
{{- end }}

{{/*
Dashboard selector labels
*/}}
{{- define "semantic-router.dashboard.selectorLabels" -}}
{{ include "semantic-router.selectorLabels" . }}
app.kubernetes.io/component: dashboard
{{- end }}
