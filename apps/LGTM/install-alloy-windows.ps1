# Variables
$alloyVersion = "v1.3.1"
$installDir = Join-Path $env:LOCALAPPDATA "Grafana Alloy"
$configDir = Join-Path $env:LOCALAPPDATA "Grafana Alloy\config"
$dataDir = Join-Path $env:LOCALAPPDATA "Grafana Alloy\data"

function Install-GrafanaAlloyWindows {
    $downloadUrl = "https://github.com/grafana/alloy/releases/download/$alloyVersion/alloy-windows-amd64.exe.zip"
    $zipPath = Join-Path $env:TEMP "alloy-windows-amd64.exe.zip"

    Write-Host "Downloading Grafana Alloy from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

    # Create installation directories
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

    # Extract the zip file
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force

    # Find the extracted executable
    $alloyExe = Get-ChildItem -Path $installDir -Recurse -Filter "alloy-windows-amd64.exe" | Select-Object -First 1

    if (-not $alloyExe) {
        throw "Could not find Grafana Alloy executable in the extracted files"
    }

    # Create a basic config file
    $configPath = Join-Path $configDir "config.yaml"
    @"
server:
  http_listen_port: 12345

logs:
  configs:
  - name: default
    clients:
      - url: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
    positions:
      filename: $dataDir/positions.yaml
    scrape_configs:
      - job_name: system
        static_configs:
          - targets:
              - localhost
        windows_events:
          use_incoming_timestamp: false
          bookmark_path: "$dataDir/bookmark.yml"
          eventlog_name: 
            - Application
            - System
            - Security
          labels:
            job: windows_events

metrics:
  global:
    scrape_interval: 60s
  configs:
    - name: default
      scrape_configs:
        - job_name: windows
          static_configs:
            - targets: ['localhost:9182']
          windows_exporter:
            enabled_collectors:
              - cpu
              - cs
              - logical_disk
              - net
              - os
              - system

traces:
  configs:
    - name: default
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
      remote_write:
        - endpoint: tempo.monitoring.svc.cluster.local:4317
          insecure: true
"@ | Out-File $configPath -Encoding utf8

    # Create Windows service
    Write-Host "Creating Grafana Alloy service..."
    $serviceBinary = "$($alloyExe.FullName) -config.file=$configPath"
    $serviceName = "GrafanaAlloy"
    $serviceDisplayName = "Grafana Alloy"
    $serviceDescription = "Grafana Alloy monitoring service"

    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        New-Service -Name $serviceName -BinaryPathName $serviceBinary -DisplayName $serviceDisplayName -Description $serviceDescription -StartupType Automatic
        
        # Start the service
        Write-Host "Starting Grafana Alloy service..."
        Start-Service -Name $serviceName
    } else {
        Write-Host "Administrator privileges are required to create and start the Windows service."
        Write-Host "Please run the following commands as an administrator to create and start the service:"
        Write-Host "New-Service -Name '$serviceName' -BinaryPathName '$serviceBinary' -DisplayName '$serviceDisplayName' -Description '$serviceDescription' -StartupType Automatic"
        Write-Host "Start-Service -Name '$serviceName'"
    }

    # Clean up
    Remove-Item $zipPath -Force

    Write-Host "Grafana Alloy has been installed on Windows."
}

# Main execution
try {
    Write-Host "Installing Grafana Alloy on Windows..."
    Install-GrafanaAlloyWindows

    Write-Host "Setup completed. Grafana Alloy is now installed on your Windows system."
    Write-Host "You can modify the Windows configuration file at: $configDir\config.yaml"
}
catch {
    Write-Host "An error occurred during setup: $_"
}