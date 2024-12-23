# Function to write colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header($text) {
    Write-ColorOutput Green "`n=== $text ===`n"
}

function Write-Success($text) {
    Write-ColorOutput Green "✔ $text"
}

function Write-Warning($text) {
    Write-ColorOutput Yellow "⚠ $text"
}

function Write-Error($text) {
    Write-ColorOutput Red "✘ $text"
}

# Variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"

# Check OpenTelemetry Collector Service
Write-Header "Checking OpenTelemetry Collector Windows Service"
$service = Get-Service -Name "OpenTelemetryCollector" -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq "Running") {
    Write-Success "OpenTelemetry Collector service is running"
} else {
    Write-Error "OpenTelemetry Collector service is not running or not found"
}

# Check OpenTelemetry Collector Logs
Write-Header "Checking OpenTelemetry Collector Logs"
try {
    $logs = Get-EventLog -LogName Application -Source "OpenTelemetryCollector" -Newest 5
    foreach ($log in $logs) {
        if ($log.EntryType -eq "Error") {
            Write-Error $log.Message
        } elseif ($log.EntryType -eq "Warning") {
            Write-Warning $log.Message
        } else {
            Write-Success $log.Message
        }
    }
} catch {
    Write-Error "Failed to retrieve OpenTelemetry Collector logs: $_"
}

# Function to set up port forwarding
function Set-PortForward($service, $localPort, $remotePort) {
    $job = Start-Job -ScriptBlock {
        param($NAMESPACE, $RELEASE_NAME, $service, $localPort, $remotePort)
        kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-$service $localPort`:$remotePort
    } -ArgumentList $NAMESPACE, $RELEASE_NAME, $service, $localPort, $remotePort

    Start-Sleep -Seconds 5  # Give it some time to establish the connection
    return $job
}

# Function to stop port forwarding
function Stop-PortForward($job) {
    Stop-Job $job
    Remove-Job $job
}

# Check Loki Data Ingestion
Write-Header "Checking Loki Data Ingestion"
$lokiJob = Set-PortForward "loki" 3100 3100
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3100/loki/api/v1/query?query={job=`"otel-collector`"}"
    if ($response.data.result) {
        Write-Success "Loki is receiving data from OpenTelemetry Collector"
    } else {
        Write-Warning "No data found in Loki for OpenTelemetry Collector"
    }
} catch {
    Write-Error "Failed to query Loki: $_"
}
Stop-PortForward $lokiJob

# Check Mimir (Prometheus) Data Ingestion
Write-Header "Checking Mimir (Prometheus) Data Ingestion"
$mimirJob = Set-PortForward "mimir" 9009 9009
try {
    $response = Invoke-RestMethod -Uri "http://localhost:9009/api/v1/query?query=up"
    if ($response.data.result) {
        Write-Success "Mimir is receiving metrics"
        $otelMetrics = $response.data.result | Where-Object { $_.metric.job -eq "otel-collector" }
        if ($otelMetrics) {
            Write-Success "Found metrics for OpenTelemetry Collector"
        } else {
            Write-Warning "No specific metrics found for OpenTelemetry Collector"
        }
    } else {
        Write-Warning "No data found in Mimir"
    }
} catch {
    Write-Error "Failed to query Mimir: $_"
}
Stop-PortForward $mimirJob

# Check Tempo for Traces
Write-Header "Checking Tempo for Traces"
$tempoJob = Set-PortForward "tempo" 3200 3200
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3200/api/traces?limit=1"
    if ($response.traces) {
        Write-Success "Tempo is receiving trace data"
    } else {
        Write-Warning "No trace data found in Tempo"
    }
} catch {
    Write-Error "Failed to query Tempo: $_"
}
Stop-PortForward $tempoJob

Write-Header "Verification Complete"
#Write-ColorOutput Cyan "If you encountered any warnings or errors, please check the OpenTelemetry Collector configuration and ensure all services are running correctly."