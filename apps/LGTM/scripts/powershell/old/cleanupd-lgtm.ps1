# Define variables
$namespace = "monitoring"
$lokiRelease = "loki"
$grafanaRelease = "grafana"
$tempoRelease = "tempo"
$mimirRelease = "mimir"
$monitoringRelease = "k8s-monitoring"
$grafanaAgentRelease = "grafana-agent"
$alloyRelease = "alloy"

# Function to delete a Helm release if it exists
function Uninstall-HelmRelease {
    param (
        [string]$releaseName,
        [string]$namespace
    )
    try {
        $releaseExists = helm list -n $namespace | Select-String $releaseName
        if ($releaseExists) {
            Write-Host "Uninstalling Helm release: $releaseName"
            helm uninstall $releaseName -n $namespace --wait
        } else {
            Write-Host "Helm release $releaseName not found, skipping..."
        }
    } catch {
        Write-Host ("Failed to uninstall Helm release " + $releaseName + ": " + $_.Exception.Message)
    }
}

# Uninstall Helm releases
Uninstall-HelmRelease -releaseName $lokiRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $grafanaRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $tempoRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $mimirRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $monitoringRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $grafanaAgentRelease -namespace $namespace
Uninstall-HelmRelease -releaseName $alloyRelease -namespace $namespace

# Delete the monitoring namespace and all resources within it
Write-Host "Deleting namespace $namespace and all associated resources..."
try {
    kubectl delete namespace $namespace --wait
} catch {
    Write-Host ("Failed to delete namespace " + $namespace + ": " + $_.Exception.Message)
}

# Verify everything is deleted
Write-Host "Verifying cleanup..."
$helmReleases = helm list -n $namespace
if ($helmReleases) {
    Write-Host ("Some Helm releases still exist in namespace " + $namespace + ":")
    Write-Host $helmReleases
} else {
    Write-Host "All Helm releases in namespace $namespace have been deleted."
}

$k8sResources = kubectl get all -n $namespace
if ($k8sResources) {
    Write-Host ("Some Kubernetes resources still exist in namespace " + $namespace + ":")
    Write-Host $k8sResources
} else {
    Write-Host "All Kubernetes resources in namespace $namespace have been deleted."
}

# Clean up any lingering PersistentVolumeClaims (PVCs)
Write-Host "Checking for lingering PersistentVolumeClaims (PVCs)..."
$pvcs = kubectl get pvc -n $namespace --no-headers | Measure-Object
if ($pvcs.Count -gt 0) {
    Write-Host "Deleting PVCs in namespace $namespace..."
    kubectl delete pvc --all -n $namespace
    Write-Host "Deleted PVCs in namespace $namespace."
} else {
    Write-Host "No PVCs found in namespace $namespace."
}
