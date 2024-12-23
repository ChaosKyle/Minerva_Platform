# Add Grafana Helm repository and update
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create a here-string for the Helm values
$helmValues = @"
cluster:
  name: my-cluster
externalServices:
  prometheus:
    host: https://prometheus-prod-13-prod-us-east-0.grafana.net
    basicAuth:
      username: "1762827"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tc2FuZGJveC1zYW5kYm94IiwiayI6IlNFbE4zMmloMUs2N3dEZDh1MDI1M3hhRyIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
  loki:
    host: https://logs-prod-006.grafana.net
    basicAuth:
      username: "980882"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tc2FuZGJveC1zYW5kYm94IiwiayI6IlNFbE4zMmloMUs2N3dEZDh1MDI1M3hhRyIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
  tempo:
    host: https://tempo-prod-04-prod-us-east-0.grafana.net:443
    basicAuth:
      username: "975197"
      password: glc_eyJvIjoiNzIxMTMyIiwibiI6InN0YWNrLTEwMjMxMDItaW50ZWdyYXRpb24tc2FuZGJveC1zYW5kYm94IiwiayI6IlNFbE4zMmloMUs2N3dEZDh1MDI1M3hhRyIsIm0iOnsiciI6InByb2QtdXMtZWFzdC0wIn19
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
    enabled: true
opencost:
  enabled: true
  opencost:
    exporter:
      defaultClusterId: my-cluster
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

# Install or upgrade Grafana K8s Monitoring using Helm
helm upgrade --install --atomic --timeout 300s grafana-k8s-monitoring grafana/k8s-monitoring `
  --namespace "default" --create-namespace --values - <<< $helmValues

# Note: The '<<<' operator in PowerShell is used to pass the here-string as input to the helm command