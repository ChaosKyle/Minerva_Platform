# Variables
$namespace = "monitoring"
$releaseName = "alloy"

# Function to install Grafana Alloy
function Install-GrafanaAlloy {
    Write-Host "Installing Grafana Alloy..."

    # Add the Grafana Helm repository
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Install Grafana Alloy
    helm upgrade --install $releaseName grafana/grafana-agent `
        --namespace $namespace `
        --create-namespace `
        --set agent.mode="flow"

    # Check the status of the deployment
    kubectl --namespace $namespace get pods -l "app.kubernetes.io/name=grafana-agent"
}

# Main execution
try {
    Install-GrafanaAlloy
    Write-Host "Grafana Alloy installation completed."
}
catch {
    Write-Host "An error occurred during installation: $_"
}