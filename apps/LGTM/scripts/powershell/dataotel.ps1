# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$OTEL_RELEASE_NAME = "otel-collector"

# Function to get the IP address of the host machine
function Get-HostIP {
    $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
    if (-not $ip) {
        $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.AddressState -eq 'Preferred' -and $_.PrefixOrigin -ne 'WellKnown' })[0].IPAddress
    }
    return $ip
}

$HOST_IP = Get-HostIP

# ... [Kubernetes deployment code remains unchanged] ...

# Install OpenTelemetry Collector on Windows
Write-Host "Installing OpenTelemetry Collector on Windows..."

# Check for Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Please install Git and try again."
    exit 1
}

# Check for Go
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "Go is not installed. Please install Go and try again."
    exit 1
}

# Clone the repository
$repoPath = "$env:USERPROFILE\opentelemetry-collector"
if (-not (Test-Path $repoPath)) {
    git clone https://github.com/open-telemetry/opentelemetry-collector.git $repoPath
}

# Navigate to the repository
Set-Location $repoPath

# Build the collector
Write-Host "Building OpenTelemetry Collector..."
Set-Location "$repoPath\cmd\otelcorecol"
go build -o otelcorecol.exe
if (-not $?) {
    Write-Host "Failed to build OpenTelemetry Collector"
    exit 1
}

# Set up the collector
$INSTALL_DIR = "$env:ProgramFiles\OpenTelemetryCollector"
$CONFIG_FILE = "$INSTALL_DIR\config.yaml"
$BINARY_PATH = "otelcorecol.exe"

# Create installation directory
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

# Copy the binary
Copy-Item $BINARY_PATH $INSTALL_DIR
if (-not $?) {
    Write-Host "Failed to copy the OpenTelemetry Collector binary"
    exit 1
}

# Create configuration file
$config = @"
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:

exporters:
  otlp:
    endpoint: ${HOST_IP}:9009
    tls:
      insecure: true
  logging:

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp, logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp, logging]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp, logging]
"@

$config | Set-Content -Path $CONFIG_FILE

# Install OpenTelemetry Collector as a Windows service
$servicePath = Join-Path $INSTALL_DIR "otelcorecol.exe"
New-Service -Name "OpenTelemetryCollector" -BinaryPathName "$servicePath --config $CONFIG_FILE" -DisplayName "OpenTelemetry Collector" -StartupType Automatic

# Start the OpenTelemetry Collector service
Start-Service -Name "OpenTelemetryCollector"
if (-not $?) {
    Write-Host "Failed to start the OpenTelemetry Collector service"
    exit 1
}

Write-Host "OpenTelemetry Collector installed and started on Windows"

Write-Host "Data ingestion setup complete!"
Write-Host "OpenTelemetry Collector has been deployed on both your local Kubernetes cluster and Windows PC."
Write-Host "Configuration file location for Windows: $CONFIG_FILE"
Write-Host "Make sure to set up port forwarding for the following services:"
Write-Host "- Loki: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-loki 3100:3100"
Write-Host "- Mimir: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-mimir 9009:9009"
Write-Host "- Tempo: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-tempo 14250:14250"