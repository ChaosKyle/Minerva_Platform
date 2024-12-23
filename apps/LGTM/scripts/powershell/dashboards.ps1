# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$GRAFANA_URL = "http://localhost:3000"
$ADMIN_PASSWORD = "your-secure-admin-password"  # Make sure this matches the password set in the deployment script

# Function to import a dashboard
function Import-Dashboard($dashboardJson, $folderName) {
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$ADMIN_PASSWORD"))
    }
    
    $body = @{
        dashboard = $dashboardJson | ConvertFrom-Json
        overwrite = $true
        folderId = 0
    }
    
    if ($folderName) {
        # Create folder if it doesn't exist
        $folderResponse = Invoke-RestMethod -Uri "$GRAFANA_URL/api/folders" -Method Post -Headers $headers -Body (@{title=$folderName} | ConvertTo-Json)
        $body.folderId = $folderResponse.id
    }

    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 100)
    Write-Host "Dashboard imported: $($response.status)"
}

# Port-forward Grafana service
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward -n $using:NAMESPACE svc/$using:RELEASE_NAME-grafana 3000:80
}

# Wait for port-forward to be ready
Start-Sleep -Seconds 5

# Import Kubernetes Overview Dashboard
$k8sOverviewJson = Invoke-WebRequest -Uri "https://grafana.com/api/dashboards/315/revisions/3/download" -UseBasicParsing | Select-Object -ExpandProperty Content
Import-Dashboard -dashboardJson $k8sOverviewJson -folderName "Kubernetes"

# Import Node Exporter Dashboard
$nodeExporterJson = Invoke-WebRequest -Uri "https://grafana.com/api/dashboards/1860/revisions/27/download" -UseBasicParsing | Select-Object -ExpandProperty Content
Import-Dashboard -dashboardJson $nodeExporterJson -folderName "Kubernetes"

# Import Windows Exporter Dashboard
$windowsExporterJson = Invoke-WebRequest -Uri "https://grafana.com/api/dashboards/10467/revisions/2/download" -UseBasicParsing | Select-Object -ExpandProperty Content
Import-Dashboard -dashboardJson $windowsExporterJson -folderName "Windows"

# Import Loki Dashboard
$lokiJson = Invoke-WebRequest -Uri "https://grafana.com/api/dashboards/12019/revisions/1/download" -UseBasicParsing | Select-Object -ExpandProperty Content
Import-Dashboard -dashboardJson $lokiJson -folderName "Logs"

# Import Tempo Dashboard
$tempoJson = Invoke-WebRequest -Uri "https://grafana.com/api/dashboards/15853/revisions/1/download" -UseBasicParsing | Select-Object -ExpandProperty Content
Import-Dashboard -dashboardJson $tempoJson -folderName "Traces"

# Stop port-forwarding
Stop-Job -Job $portForwardJob
Remove-Job -Job $portForwardJob

Write-Host "Dashboard import complete!"
Write-Host "You can now access these dashboards in Grafana at http://localhost:3000"