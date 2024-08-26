# setup.ps1

# Stop and remove existing containers
docker stop grafana prometheus kubectl-proxy 2>$null
docker rm grafana prometheus kubectl-proxy 2>$null

# Remove existing images
docker rmi monitoring-stack:latest 2>$null

# Build the Docker image
docker build -t monitoring-stack:latest .

Write-Host "Setup complete. Run 'run.ps1' to start the monitoring stack." -ForegroundColor Green
