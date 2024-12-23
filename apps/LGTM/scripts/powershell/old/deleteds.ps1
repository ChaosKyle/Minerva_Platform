param (
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [string]$GrafanaUrl = "http://localhost:3000"
)

# Function to delete a datasource by ID
function Delete-DatasourceById($id) {
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
    }

    $apiUrl = "$GrafanaUrl/api/datasources/$id"
    try {
        Invoke-RestMethod -Uri $apiUrl -Method Delete -Headers $headers
        Write-Host ("Datasource with ID: " + $id + " deleted successfully.")
    } catch {
        Write-Host ("Error deleting datasource with ID: " + $id + ":")
        if ($_.Exception.Response -ne $null) {
            Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
            Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
            Write-Host ("Response: " + $_.Exception.Message)
        } else {
            Write-Host $_.Exception.Message
        }
    }
}

# Main execution
try {
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
    }

    $apiUrl = "$GrafanaUrl/api/datasources"
    $datasources = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

    if ($datasources -ne $null -and $datasources.Count -gt 0) {
        foreach ($datasource in $datasources) {
            Delete-DatasourceById $datasource.id
        }
        Write-Host "All datasources deleted successfully."
    } else {
        Write-Host "No datasources found to delete."
    }
}
catch {
    Write-Host "An error occurred while trying to delete datasources:"
    Write-Host $_.Exception.Message
}
