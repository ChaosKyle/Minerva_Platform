# Define variables
$namespace = "monitoring"
$repoUrl = "https://grafana.github.io/helm-charts"
$gitRepo = "https://github.com/grafana/k8s-monitoring-helm.git"
$chartPath = "k8s-monitoring-helm/charts/k8s-monitoring"
$clusterName = "my-cluster"  # Change this to your desired cluster name

# Add the Grafana Helm repository
Write-Host "Adding Grafana Helm repository..."
helm repo add grafana $repoUrl
helm repo update

# Clone the k8s-monitoring-helm repository
if (-not (Test-Path $chartPath)) {
    Write-Host "Cloning the k8s-monitoring-helm repository..."
    git clone $gitRepo
}

# Create the namespace if it doesn't exist
Write-Host "Creating namespace '$namespace' if it doesn't already exist..."
$nsExists = kubectl get namespace $namespace 2>$null
if (-not $nsExists) {
    kubectl create namespace $namespace
} else {
    Write-Host "Namespace '$namespace' already exists."
}

# Update the values.yaml file with the required cluster name
Write-Host "Setting cluster name in values.yaml..."
$valuesFile = "$chartPath/values.yaml"
$valuesContent = Get-Content $valuesFile

# Check if cluster.name is already set
if ($valuesContent -notmatch "cluster:\s+name:") {
    $valuesContent = $valuesContent + "`ncluster:`n  name: $clusterName"
    Set-Content $valuesFile $valuesContent
}

# Deploy the k8s-monitoring Helm chart
Write-Host "Deploying the k8s-monitoring Helm chart..."
Set-Location -Path $chartPath
helm install k8s-monitoring . -n $namespace

# Port-forward Grafana to access it on localhost
Write-Host "Port-forwarding Grafana service to http://localhost:3000..."
Start-Process -NoNewWindow powershell -ArgumentList "kubectl port-forward svc/grafana 3000:80 -n $namespace"

Write-Host "Deployment completed. Visit http://localhost:3000 to access Grafana."
