# Variables
$namespace = "monitoring"
$lokiRelease = "loki"
$grafanaRelease = "grafana"
$tempoRelease = "tempo"
$mimirRelease = "mimir"
$monitoringRelease = "my-monitoring"
$grafanaAdminPassword = "Milk$$Dud$$"  # Set your desired Grafana admin password here
$storageClassName = "standard"  # Replace with your storage class name if different
$grafanaStorageSize = "2Gi"  # Adjust the size as needed
$lokiStorageSize = "5Gi"  # Adjust the size as needed
$tempoStorageSize = "5Gi"  # Adjust the size as needed
$mimirStorageSize = "5Gi"  # Adjust the size as needed
$k8sMonitoringChartPath = "./k8s-monitoring"

# Add Grafana Helm repository
Write-Host "Adding Grafana Helm repository..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Delete any existing releases
Write-Host "Deleting existing releases (if any)..."
helm uninstall $lokiRelease -n $namespace -ErrorAction SilentlyContinue
helm uninstall $grafanaRelease -n $namespace -ErrorAction SilentlyContinue
helm uninstall $tempoRelease -n $namespace -ErrorAction SilentlyContinue
helm uninstall $mimirRelease -n $namespace -ErrorAction SilentlyContinue
helm uninstall $monitoringRelease -n $namespace -ErrorAction SilentlyContinue

# Create the namespace
Write-Host "Creating namespace '$namespace' (if not exists)..."
$nsExists = kubectl get namespace $namespace -ErrorAction SilentlyContinue
if (-not $nsExists) {
    kubectl create namespace $namespace
} else {
    Write-Host "Namespace '$namespace' already exists."
}

# Deploy Loki with persistent storage
Write-Host "Deploying Loki with persistent storage..."
helm install $lokiRelease grafana/loki-stack -n $namespace `
    --set persistence.enabled=true `
    --set persistence.storageClassName=$storageClassName `
    --set persistence.size=$lokiStorageSize

# Deploy Grafana with custom admin password and persistent storage
Write-Host "Deploying Grafana with custom admin password and persistent storage..."
helm install $grafanaRelease grafana/grafana -n $namespace `
    --set adminPassword=$grafanaAdminPassword `
    --set persistence.enabled=true `
    --set persistence.storageClassName=$storageClassName `
    --set persistence.size=$grafanaStorageSize

# Deploy Tempo with persistent storage
Write-Host "Deploying Tempo with persistent storage..."
helm install $tempoRelease grafana/tempo -n $namespace `
    --set storage.trace_storage.trace.persistence.enabled=true `
    --set storage.trace_storage.trace.persistence.storageClassName=$storageClassName `
    --set storage.trace_storage.trace.persistence.size=$tempoStorageSize

# Deploy Mimir with persistent storage
Write-Host "Deploying Mimir with persistent storage..."
helm install $mimirRelease grafana/mimir-distributed -n $namespace `
    --set memcached.persistence.enabled=true `
    --set memcached.persistence.storageClassName=$storageClassName `
    --set memcached.persistence.size=$mimirStorageSize

# Clone the k8s-monitoring Helm chart repository
if (-Not (Test-Path $k8sMonitoringChartPath)) {
    Write-Host "Cloning the k8s-monitoring Helm chart repository..."
    git clone https://github.com/grafana/k8s-monitoring-helm.git
    Set-Location -Path "k8s-monitoring-helm/charts/k8s-monitoring"
}

# Update k8s-monitoring values.yaml for LGTM
Write-Host "Updating values.yaml for k8s-monitoring..."
$valuesPath = "$k8sMonitoringChartPath/values.yaml"
(Get-Content $valuesPath) -replace 'externalServices:\n  prometheus:\n    enabled: false',
'externalServices:
  prometheus:
    enabled: true
    host: "http://mimir-distributed.monitoring.svc.cluster.local:9090"

  loki:
    enabled: true
    host: "http://loki.monitoring.svc.cluster.local:3100"' | Set-Content $valuesPath

# Deploy the k8s-monitoring Helm chart
Write-Host "Deploying the k8s-monitoring Helm chart..."
helm install $monitoringRelease . -n $namespace

# Verify deployments
Write-Host "Verifying deployments..."
kubectl get all -n $namespace

# Port-forward Grafana for access
Write-Host "Port-forwarding Grafana service to http://localhost:3000..."
kubectl port-forward svc/grafana 3000:80 -n $namespace

Write-Host "Deployment completed. You can access Grafana at http://localhost:3000 with the admin password: $grafanaAdminPassword"
