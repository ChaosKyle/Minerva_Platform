# run.ps1

# Create Docker network
docker network create monitoring-network 2>$null

# Run Grafana
docker run -d --name grafana `
    --network monitoring-network `
    -p 3000:3000 `
    -v "${PWD}/configs:/etc/grafana" `
    monitoring-stack:latest

# Run Prometheus
docker run -d --name prometheus `
    --network monitoring-network `
    -p 9090:9090 `
    -v "${PWD}/configs/prometheus.yml:/etc/prometheus/prometheus.yml" `
    prom/prometheus:latest

# Run kubectl-proxy
docker run -d --name kubectl-proxy `
    --network host `
    bitnami/kubectl:latest `
    kubectl proxy --address 0.0.0.0 --port 8080

Write-Host "Monitoring stack is now running." -ForegroundColor Green
Write-Host "Access Grafana at http://localhost:3000" -ForegroundColor Yellow
Write-Host "Default credentials: admin / admin" -ForegroundColor Yellow
