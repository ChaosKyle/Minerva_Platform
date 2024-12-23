# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$ADMIN_PASSWORD = "your-secure-admin-password"
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

# Create service account and API key
kubectl -n $NAMESPACE create serviceaccount lgtm-admin
kubectl -n $NAMESPACE create clusterrolebinding lgtm-admin-binding --clusterrole=cluster-admin --serviceaccount=$NAMESPACE`:lgtm-admin

# Get the token for the service account
$TOKEN = kubectl -n $NAMESPACE create token lgtm-admin

# Create API key in Grafana using the Grafana API
$GRAFANA_POD = kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}"
$GRAFANA_URL = "http://localhost:3000"

# Port-forward Grafana
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward -n $using:NAMESPACE $using:GRAFANA_POD 3000:3000
}

# Wait for port-forward to be ready
Start-Sleep -Seconds 5

# Create API key with 1-hour expiration
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$ADMIN_PASSWORD"))
}

$expirationTime = [int][double]::Parse((Get-Date -UFormat %s)) + 3600  # Current Unix timestamp + 1 hour

$body = @{
    "name" = "LGTM-Admin-Key"
    "role" = "Admin"
    "secondsToLive" = 3600  # 1 hour in seconds
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/auth/keys" -Method Post -Headers $headers -Body $body
    $API_KEY = $response.key
    Write-Host "Grafana API key created successfully. It will expire in 1 hour."
    Write-Host "API Key: $API_KEY"
    Write-Host "Expiration time: $((Get-Date).AddSeconds(3600).ToString('yyyy-MM-dd HH:mm:ss'))"
} catch {
    Write-Host "Failed to create Grafana API key. Error: $_"
}

# Stop port-forwarding
Stop-Job -Job $portForwardJob
Remove-Job -Job $portForwardJob

Write-Host "Service account token: $TOKEN"

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

# Apply dashboard templates
$DASHBOARD_URLS = @(
    "https://grafana.com/api/dashboards/13105/revisions/2/download",  # Kubernetes Cluster Monitoring (via Prometheus)
    "https://grafana.com/api/dashboards/14830/revisions/1/download",  # Loki Dashboard
    "https://grafana.com/api/dashboards/12740/revisions/1/download"   # Tempo Dashboard
)

foreach ($url in $DASHBOARD_URLS) {
    try {
        $dashboardJson = Invoke-WebRequest -Uri $url -UseBasicParsing | Select-Object -ExpandProperty Content
        $dashboardName = [Guid]::NewGuid().ToString()
        $dashboardConfigMap = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-$dashboardName
  labels:
    grafana_dashboard: "1"
data:
  $dashboardName.json: |
$($dashboardJson -replace '^', '    ')
"@
        $dashboardConfigMap | kubectl -n $NAMESPACE apply -f -
        Write-Host "Dashboard applied successfully."
    } catch {
        Write-Host "Failed to apply dashboard from $url. Error: $_"
    }
}

Write-Host "LGTM stack deployment complete!"