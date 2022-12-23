{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "cr.imagePullSecrets" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 does not support it, so we need to implement this if-else logic.
Also, we can not use a single if because lazy evaluation is not an option
*/}}
{{- if .Values.config }}
{{- if .Values.config.cr_image_pull_secrets }}
imagePullSecrets:
{{- range .Values.config.cr_image_pull_secrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}