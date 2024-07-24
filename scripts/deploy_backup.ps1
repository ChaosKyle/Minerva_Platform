# Deploy script for Minerva Platform

# Function to check and run a container
function Ensure-ContainerRunning {
    param (
        [string]$containerName,
        [string]$imageName,
        [string]$port
    )

    $container = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
    
    if ($container -eq $containerName) {
        Write-Host "Stopping and removing existing $containerName container..."
        docker stop $containerName
        docker rm $containerName
    }

    Write-Host "Creating and starting $containerName..."
    docker run -d --name $containerName -p $port`:$port $imageName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to start $containerName. Please check if the image exists and the port $port is available."
    }
}

# Variables
$siteName = "Minerva"
$sourcePath = $PSScriptRoot
$iisPath = "C:\inetpub\wwwroot\Minerva"
$port = 8080

# Ensure IIS is running
$iisStatus = Get-Service -Name W3SVC
if ($iisStatus.Status -ne 'Running') {
    Write-Host "Starting IIS..."
    Start-Service -Name W3SVC
} else {
    Write-Host "IIS is already running."
}

# Ensure Minerva website directory exists in IIS path
if (-not (Test-Path $iisPath)) {
    New-Item -ItemType Directory -Path $iisPath -Force
}

# Copy necessary files to IIS path
Copy-Item -Path "$sourcePath\index.html" -Destination $iisPath -Force
Copy-Item -Path "$sourcePath\css" -Destination "$iisPath\css" -Recurse -Force
Copy-Item -Path "$sourcePath\images" -Destination "$iisPath\images" -Recurse -Force

# Ensure Minerva website is set up in IIS
if (-not (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
    Write-Host "Setting up Minerva website in IIS..."
    New-Website -Name $siteName -PhysicalPath $iisPath -Port $port
} else {
    Write-Host "Updating Minerva website in IIS..."
    Set-ItemProperty -Path "IIS:\Sites\$siteName" -Name "physicalPath" -Value $iisPath
}

# Check if Docker Desktop is running
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($null -eq $dockerProcess) {
    Write-Host "Docker Desktop is not running. Please start Docker Desktop and run this script again."
    exit
}

# Ensure containers are running
Ensure-ContainerRunning -containerName "chore-tracker" -imageName "chore-tracker" -port 8081
Ensure-ContainerRunning -containerName "meal-tracker" -imageName "meal-tracker" -port 8082
Ensure-ContainerRunning -containerName "travel-planner" -imageName "travel-planner" -port 8501
Ensure-ContainerRunning -containerName "grafana" -imageName "grafana/grafana" -port 3000

# Test website accessibility
$webClient = New-Object System.Net.WebClient
try {
    $content = $webClient.DownloadString("http://localhost:$port")
    Write-Host "Website is accessible."
} catch {
    Write-Host "Failed to access the website. Error: $_"
    Write-Host "Please check IIS logs and website configuration."
}

Write-Host "Deployment complete. Minerva Platform should now be accessible at http://localhost:8080"