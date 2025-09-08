{{/*
Usage: {{ include "list.whitelist" . }}
*/}}
{{- define "list.whitelist" -}}
{{- $all := list -}}
{{- range $name, $ips := .Values.IPs }}
  {{- $all = concat $all $ips }}
{{- end }}
{{- join "," (uniq $all) -}}
{{- end -}}
