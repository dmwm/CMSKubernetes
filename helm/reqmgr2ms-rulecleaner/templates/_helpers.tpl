{{- define "actionValidate" -}}
  {{ $action := .Values.actions }}
  {{- if or (eq $action "action1") (eq $action "action2") (eq $action "action3") -}}
    true
  {{- end -}}
{{- end -}}

