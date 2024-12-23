# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$GRAFANA_AGENT_RELEASE = "grafana-agent"
$TIMEOUT_SECONDS = 60

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Function to run a command with a timeout
function Invoke-CommandWithTimeout {
    param (
        [scriptblock]$ScriptBlock,
        [int]$Timeout
    )

    $job = Start-Job -ScriptBlock $ScriptBlock

    if (Wait-Job $job -Timeout $Timeout) {
        Receive-Job $job
    } else {
        Write-Host "Command timed out after $Timeout seconds."
        Remove-Job -Force $job
    }
}

# Check if kubectl is installed
if (-not (Test-Command kubectl)) {
    Write-Host "kubectl is not installed or not in PATH. Please install kubectl and try again."
    exit 1
}

# Check if helm is installed
if (-not (Test-Command helm)) {
    Write-Host "helm is not installed or not in PATH. Please install helm and try again."
    exit 1
}

# Remove LGTM stack from Kubernetes
Write-Host "Removing LGTM stack from Kubernetes..."
Invoke-CommandWithTimeout -ScriptBlock { helm uninstall $using:RELEASE_NAME -n $using:NAMESPACE } -Timeout $TIMEOUT_SECONDS

# Try to remove Grafana Agent, but don't fail if it's not found
Write-Host "Attempting to remove Grafana Agent from Kubernetes..."
Invoke-CommandWithTimeout -ScriptBlock { 
    helm uninstall $using:GRAFANA_AGENT_RELEASE -n $using:NAMESPACE
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Grafana Agent release not found. Skipping..."
    }
} -Timeout $TIMEOUT_SECONDS

# Remove the namespace
Write-Host "Removing namespace $NAMESPACE..."
Invoke-CommandWithTimeout -ScriptBlock { kubectl delete namespace $NAMESPACE } -Timeout $TIMEOUT_SECONDS

# Remove Grafana Agent from Windows
Write-Host "Removing Grafana Agent from Windows..."
$serviceName = "Grafana Agent"
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    Stop-Service -Name $serviceName -Force
    $agentPath = (Get-WmiObject win32_service | Where-Object {$_.Name -eq $serviceName}).PathName
    $agentPath = $agentPath -replace '^"|"$' # Remove quotes if present
    if ($agentPath) {
        & $agentPath --service.uninstall
        Write-Host "Grafana Agent service uninstalled."
    } else {
        Write-Host "Could not determine Grafana Agent path. Manual uninstallation may be required."
    }
} else {
    Write-Host "Grafana Agent service not found."
}

# Remove Grafana Agent files
$INSTALL_DIR = "C:\Program Files\Grafana Agent"
if (Test-Path $INSTALL_DIR) {
    Remove-Item -Path $INSTALL_DIR -Recurse -Force
    Write-Host "Grafana Agent files removed from $INSTALL_DIR"
} else {
    Write-Host "Grafana Agent directory not found at $INSTALL_DIR"
}

# Remove Helm repos
Write-Host "Removing Helm repositories..."
helm repo remove grafana

# Clean up any lingering port-forwards
Get-NetTCPConnection -LocalPort 3000, 9090, 3100, 4317 -ErrorAction SilentlyContinue | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    if ($process -and $process.Name -eq "kubectl") {
        Stop-Process -Id $_.OwningProcess -Force
        Write-Host "Stopped port-forward on port $($_.LocalPort)"
    }
}

Write-Host "Cleanup complete. You can now start over with a fresh installation."