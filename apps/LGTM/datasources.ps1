param (
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [string]$GrafanaUrl = "http://localhost:3000"
)

# Function to create a datasource
function Create-Datasource($name, $type, $url) {
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
        "Authorization" = "Bearer $ApiKey"
    }
    $body = @{
        name = $name
        type = $type
        url = $url
        access = "proxy"
        isDefault = ($name -eq "Prometheus")
    } | ConvertTo-Json

    $apiUrl = "$GrafanaUrl/api/datasources"
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers
        
        if ($result.id) {
            Write-Host ("Datasource " + $name + " created successfully with ID: " + $result.id)
        } else {
            Write-Host ("Datasource " + $name + " created but response was unexpected:")
            $result | ConvertTo-Json | Write-Host
        }
    } catch {
        Write-Host ("Error creating datasource " + $name + ":")
        if ($_.Exception.Response -ne $null) {
            Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
            Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
            Write-Host ("Response: " + $_.Exception.Message)
        } else {
            Write-Host $_.Exception.Message
        }
    }
}

# Function to check Grafana health
function Check-GrafanaHealth {
    $healthUrl = "$GrafanaUrl/api/health"
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get
        Write-Host "Grafana health check: OK"
        return $true
    } catch {
        Write-Host "Grafana health check failed:"
        if ($_.Exception.Response -ne $null) {
            Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
            Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
            Write-Host ("Response: " + $_.Exception.Message)
        } else {
            Write-Host $_.Exception.Message
        }
        return $false
    }
}

# Main execution
try {
    Write-Host "Checking Grafana health..."
    if (-not (Check-GrafanaHealth)) {
        throw "Grafana health check failed. Please ensure Grafana is running and accessible."
    }

    Write-Host "Creating datasources..."
    Create-Datasource "Prometheus" "prometheus" "http://mimir-nginx.monitoring:80/prometheus"
    Create-Datasource "Loki" "loki" "http://loki.monitoring:3100"
    Create-Datasource "Tempo" "tempo" "http://tempo.monitoring:3200"  # Corrected port to 3200

    Write-Host "Datasources setup completed."
}
catch {
    Write-Host "An error occurred during datasources setup:"
    Write-Host $_.Exception.Message
}
