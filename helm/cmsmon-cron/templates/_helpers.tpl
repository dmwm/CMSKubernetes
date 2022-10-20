{{/*
Expand the name of the chart.
*/}}
{{- define "cmsmon-cron.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cmsmon-cron.fullname" -}}
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
{{- define "cmsmon-cron.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cmsmon-cron.labels" -}}
helm.sh/chart: {{ include "cmsmon-cron.chart" . }}
{{ include "cmsmon-cron.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cmsmon-cron.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cmsmon-cron.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cmsmon-cron.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cmsmon-cron.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Compile CronJob run command with all parameters
*/}}
{{- define "cmsmon-cron.run" -}}
{{ $.cron.command }} {{ $.cron.args }} --p1=${{ $.cron.name | upper | replace "-" "_" }}_SERVICE_PORT_PORT_1 --p2=${{ $.cron.name | upper | replace "-" "_" }}_SERVICE_PORT_PORT_2 --host=$MY_NODE_NAME --wdir=$WDIR {{ if and (eq $.Values.test.enabled true) (eq $.cron.testFlagExists true) }}--test{{ end }} 2>&1
{{- end }}