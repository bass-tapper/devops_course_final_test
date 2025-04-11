{{- define "rick-api.name" -}}
rick-api
{{- end }}

{{- define "rick-api.fullname" -}}
{{ include "rick-api.name" . }}-{{ .Release.Name }}
{{- end }}

{{- define "rick-api.labels" -}}
app.kubernetes.io/name: {{ include "rick-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "rick-api.chartLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "rick-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rick-api.name" . }}
{{- end }}

{{- define "rick-api.safeName" -}}
{{ .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}