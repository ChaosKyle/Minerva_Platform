# Set the namespace
$namespace = "monitoring"

# Function to force delete a pod
function Force-DeletePod($podName) {
    Write-Host "Force deleting pod: $podName"
    kubectl delete pod $podName -n $namespace --force --grace-period=0
}

# Function to check and fix the Grafana pod
function Check-GrafanaPod {
    $grafanaPod = kubectl get pod -n $namespace -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].metadata.name}"
    $podStatus = kubectl get pod $grafanaPod -n $namespace -o jsonpath="{.status.phase}"
    
    if ($podStatus -eq "Pending") {
        Write-Host "Grafana pod is pending. Checking events..."
        kubectl describe pod $grafanaPod -n $namespace
        
        $userInput = Read-Host "Do you want to delete and let it recreate? (y/n)"
        if ($userInput -eq "y") {
            kubectl delete pod $grafanaPod -n $namespace
        }
    } else {
        Write-Host "Grafana pod status: $podStatus"
    }
}

# Main execution
try {
    # Check for any terminating pods
    $terminatingPods = kubectl get pods -n $namespace | Select-String "Terminating"
    foreach ($pod in $terminatingPods) {
        $podName = ($pod -split '\s+')[0]
        Force-DeletePod $podName
    }

    # Check Grafana pod
    Check-GrafanaPod

    # Verify Alloy agent is running
    $alloyPod = kubectl get pod -n $namespace -l app.kubernetes.io/name=grafana-agent -o jsonpath="{.items[0].metadata.name}"
    $alloyStatus = kubectl get pod $alloyPod -n $namespace -o jsonpath="{.status.phase}"
    Write-Host "Alloy agent pod ($alloyPod) status: $alloyStatus"

    # List all pods in the namespace
    Write-Host "`nCurrent pods in the $namespace namespace:"
    kubectl get pods -n $namespace

    Write-Host "`nCleanup and verification completed."
}
catch {
    Write-Host "An error occurred during cleanup: $_"
}