# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$ADMIN_PASSWORD = "admin"
$REPO_URL = "https://grafana.github.io/helm-charts"
$CHART_NAME = "lgtm-distributed"

# Add the Grafana Helm repository
helm repo add grafana $REPO_URL
helm repo update

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy LGTM stack
helm upgrade --install $RELEASE_NAME grafana/$CHART_NAME `
  --namespace $NAMESPACE `
  --set "loki.auth_enabled=false" `
  --set "grafana.enabled=true,grafana.adminPassword=$ADMIN_PASSWORD" `
  --set "prometheus.enabled=true,prometheus.server.persistentVolume.enabled=true" `
  --set "tempo.enabled=true,tempo.persistence.enabled=true" `
  --wait

# Wait for Grafana pod to be ready
$retries = 0
$maxRetries = 10
$grafanaPodReady = $false

while (-not $grafanaPodReady -and $retries -lt $maxRetries) {
    $grafanaPod = kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].status.phase}"
    if ($grafanaPod -eq "Running") {
        $grafanaPodReady = $true
    } else {
        Write-Host "Waiting for Grafana pod to be ready... (Attempt $($retries + 1))"
        Start-Sleep -Seconds 10
        $retries++
    }
}

if (-not $grafanaPodReady) {
    Write-Host "Grafana pod did not become ready in time. Please check the pod status manually."
    exit 1
}

# Setup data sources
$DATASOURCES_YAML = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  labels:
    grafana_datasource: "1"
data:
  datasources.yaml: |-
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://$RELEASE_NAME-prometheus-server:80
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://$RELEASE_NAME-loki:3100
      access: proxy
    - name: Tempo
      type: tempo
      url: http://$RELEASE_NAME-tempo:3100
      access: proxy
"@

$DATASOURCES_YAML | kubectl -n $NAMESPACE apply -f -

Write-Host "LGTM stack deployment and data source setup complete!"

# Add Grafana access instructions
Write-Host "`nTo access Grafana:"
Write-Host "1. Run the following command to set up port forwarding:"
Write-Host "   kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-grafana 3000:80"
Write-Host "2. Open a web browser and go to: http://localhost:3000"
Write-Host "3. Log in with the following credentials:"
Write-Host "   Username: admin"
Write-Host "   Password: $ADMIN_PASSWORD"