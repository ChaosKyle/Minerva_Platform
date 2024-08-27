# Variables
$namespace = "monitoring"
$lokiRelease = "loki"
$grafanaRelease = "grafana"
$tempoRelease = "tempo"
$mimirRelease = "mimir"
$monitoringRelease = "my-monitoring"

# Function to safely run a command and handle errors
function Safe-Run($command) {
    try {
        Invoke-Expression $command
    } catch {
        Write-Host "Error executing: $command" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Uninstall Helm releases
Write-Host "Uninstalling Helm releases..."
Safe-Run "helm uninstall $lokiRelease -n $namespace"
Safe-Run "helm uninstall $grafanaRelease -n $namespace"
Safe-Run "helm uninstall $tempoRelease -n $namespace"
Safe-Run "helm uninstall $mimirRelease -n $namespace"
Safe-Run "helm uninstall $monitoringRelease -n $namespace"

# Delete the namespace
Write-Host "Deleting namespace '$namespace'..."
Safe-Run "kubectl delete namespace $namespace"

# Delete any remaining Persistent Volume Claims (PVCs)
Write-Host "Deleting any remaining Persistent Volume Claims (PVCs)..."
Safe-Run "kubectl delete pvc --all -n $namespace"

# Delete any remaining Persistent Volumes (PVs)
Write-Host "Deleting any remaining Persistent Volumes (PVs)..."
Safe-Run "kubectl delete pv --all -n $namespace"

# Clean up any dangling ConfigMaps or Secrets
Write-Host "Deleting any remaining ConfigMaps and Secrets..."
Safe-Run "kubectl delete configmap --all -n $namespace"
Safe-Run "kubectl delete secret --all -n $namespace"

# Optionally, delete orphaned Helm releases if necessary
Write-Host "Deleting any orphaned Helm releases..."
$helmList = helm list --all-namespaces | Where-Object { $_.STATUS -eq "deployed" -or $_.STATUS -eq "failed" }
foreach ($release in $helmList) {
    Safe-Run "helm uninstall $($release.NAME) -n $($release.NAMESPACE)"
}

Write-Host "Cleanup completed. Your environment is now clean."
  