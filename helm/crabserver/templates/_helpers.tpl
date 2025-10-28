{{/*
Expand the name of the chart.
*/}}
{{- define "crabserver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "crabserver.fullname" -}}
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
{{- define "crabserver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "crabserver.labels" -}}
helm.sh/chart: {{ include "crabserver.chart" . }}
{{ include "crabserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "crabserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "crabserver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "crabserver.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "crabserver.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a configHash for ConfigMap content-based versioning to trigger automatic rollouts.
*/}}
{{- define "crabserver.configHash" -}}
{{- $content := "" -}}
{{- if .Values.crabserver.configPy }}
{{- $content = .Values.crabserver.configPy -}}
{{- else }}
{{- $path := printf "config/%s/config.py" .Values.environment -}}
{{- $content = .Files.Get $path -}}
{{- end }}
{{- $hash := sha256sum $content | trunc 8 -}}
{{- $hash -}}
{{- end }}

{{- define "filebeat.configHash" -}}
{{- $content := .Files.Get "config/filebeat.yml" -}}
{{- $hash := sha256sum $content | trunc 8 -}}
{{- $hash -}}
{{- end }}
