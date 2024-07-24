# Define variables
$siteName = "Minerva"
$sitePath = "C:\inetpub\wwwroot\Minerva"
$rootPath = "C:\Users\Kylel\Lobby\Minerva"  # Adjust this to your actual root directory path
$port = 8080

# Function to ensure a container is running
function Ensure-ContainerRunning($name, $image, $port) {
    $container = docker ps -q -f name=$name
    if ($container) {
        Write-Host "$name is already running."
    } else {
        Write-Host "Starting $name..."
        docker run -d --name $name -p "${port}:${port}" $image
    }
}

# Stop and remove the existing IIS website
if (Get-Website -Name $siteName) {
    Remove-Website -Name $siteName
}

# Create the IIS website directory if it doesn't exist
if (-not (Test-Path $sitePath)) {
    New-Item -ItemType Directory -Path $sitePath -Force
}

# Copy the index.html and other necessary files from the root directory
Copy-Item "$rootPath\index.html" $sitePath -Force
Copy-Item "$rootPath\css" $sitePath -Recurse -Force
Copy-Item "$rootPath\images" $sitePath -Recurse -Force

# Create the new IIS website
New-Website -Name $siteName -PhysicalPath $sitePath -Port $port

# Ensure all containers are running
Ensure-ContainerRunning "chore-tracker" "chore-tracker" 8081
Ensure-ContainerRunning "meal-tracker" "meal-tracker" 8082
Ensure-ContainerRunning "fitness-planner" "fitness-planner" 8503
Ensure-ContainerRunning "travel-planner" "travel-planner" 8501
Ensure-ContainerRunning "google-calendar-app" "google-calendar-app" 8505
Ensure-ContainerRunning "grafana" "grafana/grafana" 3000

Write-Host "Deployment complete. Minerva Platform should now be accessible at http://localhost:$port"