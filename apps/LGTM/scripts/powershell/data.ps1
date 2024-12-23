# Set variables
$NAMESPACE = "lgtm"
$RELEASE_NAME = "lgtm-stack"
$ALLOY_VERSION = "v1.3.1"
$ALLOY_RELEASE_NAME = "grafana-alloy"

# Function to get the IP address of the host machine
function Get-HostIP {
    $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
    if (-not $ip) {
        $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.AddressState -eq 'Preferred' -and $_.PrefixOrigin -ne 'WellKnown' })[0].IPAddress
    }
    return $ip
}

$HOST_IP = Get-HostIP

# Deploy Grafana Alloy for Kubernetes
Write-Host "Deploying Grafana Alloy for Kubernetes..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

$values = @"
agent:
  mode: flow
  configMap:
    create: true
    content: |
      logs:
        configs:
        - name: default
          clients:
            - url: http://$RELEASE_NAME-loki.${NAMESPACE}.svc.cluster.local:3100/loki/api/v1/push
          positions:
            filename: /tmp/positions.yaml
          scrape_configs:
            - job_name: pod-logs
              kubernetes_sd_configs:
                - role: pod
              pipeline_stages:
                - docker: {}
      metrics:
        configs:
        - name: default
          remote_write:
            - url: http://$RELEASE_NAME-mimir.${NAMESPACE}.svc.cluster.local:9009/api/v1/push
          scrape_configs:
            - job_name: kubernetes-pods
              kubernetes_sd_configs:
                - role: pod
      traces:
        configs:
        - name: default
          remote_write:
            - endpoint: ${RELEASE_NAME}-tempo.${NAMESPACE}.svc.cluster.local:4317
              insecure: true
          receivers:
            otlp:
              protocols:
                grpc:
                  endpoint: 0.0.0.0:4317
                http:
                  endpoint: 0.0.0.0:4318
"@

$valuesFile = "alloy-values.yaml"
$values | Out-File -FilePath $valuesFile -Encoding utf8

helm upgrade --install $ALLOY_RELEASE_NAME grafana/grafana-agent `
  --namespace $NAMESPACE `
  --values $valuesFile

# Install Grafana Alloy on Windows
Write-Host "Installing Grafana Alloy on Windows..."
$INSTALL_DIR = "$env:ProgramFiles\GrafanaAlloy"
$CONFIG_FILE = "$INSTALL_DIR\alloy-config.yaml"
$ALLOY_VERSION = "v1.3.1"

# Create installation directory
try {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    Write-Host "Installation directory created: $INSTALL_DIR"
} catch {
    Write-Host "Error creating installation directory: $_"
    exit 1
}

# Download Grafana Alloy
try {
    $ProgressPreference = 'SilentlyContinue'
    $downloadUrl = "https://github.com/grafana/alloy/releases/download/$ALLOY_VERSION/alloy-windows-amd64.exe.zip"
    $zipPath = "$INSTALL_DIR\alloy.zip"
    $exePath = "$INSTALL_DIR\grafana-alloy.exe"

    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $INSTALL_DIR -Force
    Remove-Item $zipPath

    if (Test-Path $exePath) {
        Write-Host "Grafana Alloy downloaded and extracted successfully"
    } else {
        throw "Grafana Alloy executable not found after extraction"
    }
} catch {
    Write-Host "Error downloading or extracting Grafana Alloy: $_"
    exit 1
}

# Create configuration file
$config = @"
logs:
  configs:
  - name: windows
    clients:
      - url: http://${HOST_IP}:3100/loki/api/v1/push
    positions:
      filename: $INSTALL_DIR\positions.yaml
    scrape_configs:
      - job_name: windows_events
        windows_events:
          use_incoming_timestamp: true
          eventlog_name: 
            - "Application"
            - "System"
          xpath_query: '*'
        relabel_configs:
          - source_labels: ['computer']
            target_label: 'host'

metrics:
  global:
    scrape_interval: 60s
  configs:
  - name: windows
    scrape_configs:
      - job_name: windows
        windows_exporter:
          enabled: true
    remote_write:
      - url: http://${HOST_IP}:9009/api/v1/push

traces:
  configs:
  - name: default
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    remote_write:
      - endpoint: ${HOST_IP}:4317
        insecure: true
        protocol: grpc
"@

try {
    $config | Set-Content -Path $CONFIG_FILE
    Write-Host "Configuration file created: $CONFIG_FILE"
} catch {
    Write-Host "Error creating configuration file: $_"
    exit 1
}

# Install Grafana Alloy as a Windows service
try {
    Start-Process -FilePath $exePath -ArgumentList "--config.file=$CONFIG_FILE --service.install" -NoNewWindow -Wait
    Write-Host "Grafana Alloy service installed"
} catch {
    Write-Host "Error installing Grafana Alloy service: $_"
    exit 1
}

# Start the Grafana Alloy service
try {
    Start-Service -Name "grafana-agent"
    Write-Host "Grafana Alloy service started"
} catch {
    Write-Host "Error starting Grafana Alloy service: $_"
    exit 1
}

Write-Host "Data ingestion setup complete!"
Write-Host "Grafana Alloy has been installed on both your local Kubernetes cluster and Windows PC."
Write-Host "Configuration file location for Windows: $CONFIG_FILE"
Write-Host "Make sure to set up port forwarding for the following services:"
Write-Host "- Loki: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-loki 3100:3100"
Write-Host "- Mimir: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-mimir 9009:9009"
Write-Host "- Tempo: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-tempo 4317:4317"