# PowerShell script to install Grafana K8s Monitoring using Helm

# Add the Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts

# Update the Helm repositories
helm repo update

# Define the values for the Helm chart
$values = @"
cluster:
  name: docker-desktop
externalServices:
  prometheus:
    host: https://prometheus-prod-13-prod-us-east-0.grafana.net
    basicAuth:
      username: "1762827"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tZGVza3RvcC1kZXNrdG9wIiwiayI6IjMwMEE4dWFjdzhCNTIwNmJJaFQweFV3TiIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
  loki:
    host: https://logs-prod-006.grafana.net
    basicAuth:
      username: "980882"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tZGVza3RvcC1kZXNrdG9wIiwiayI6IjMwMEE4dWFjdzhCNTIwNmJJaFQweFV3TiIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
  tempo:
    host: https://tempo-prod-04-prod-us-east-0.grafana.net:443
    basicAuth:
      username: "975197"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tZGVza3RvcC1kZXNrdG9wIiwiayI6IjMwMEE4dWFjdzhCNTIwNmJJaFQweFV3TiIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
metrics:
  enabled: true
  alloy:
    metricsTuning:
      useIntegrationAllowList: true
  cost:
    enabled: true
  kepler:
    enabled: true
  node-exporter:
    enabled: true
logs:
  enabled: true
  pod_logs:
    enabled: true
  cluster_events:
    enabled: true
traces:
  enabled: true
receivers:
  grpc:
    enabled: true
  http:
    enabled: true
  zipkin:
    enabled: true
  grafanaCloudMetrics:
    enabled: false
opencost:
  enabled: true
  opencost:
    exporter:
      defaultClusterId: docker-desktop
    prometheus:
      external:
        url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom
kube-state-metrics:
  enabled: true
prometheus-node-exporter:
  enabled: true
prometheus-operator-crds:
  enabled: true
kepler:
  enabled: true
alloy: {}
alloy-events: {}
alloy-logs: {}
"@

# Save the values to a temporary file
$valuesFile = [System.IO.Path]::GetTempFileName()
$values | Out-File -FilePath $valuesFile -Encoding utf8

# Install or upgrade the Helm chart
helm upgrade --install --atomic --timeout 300s grafana-k8s-monitoring grafana/k8s-monitoring `
  --namespace "default" --create-namespace --values $valuesFile

# Clean up the temporary file
Remove-Item $valuesFile