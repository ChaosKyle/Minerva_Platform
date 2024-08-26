# jumbo_setup.ps1

# Function to write messages
function Write-Message {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Create directory structure
Write-Message "Creating directory structure..." -Color Yellow
New-Item -ItemType Directory -Force -Path .\configs | Out-Null

# Create setup.ps1
Write-Message "Creating setup.ps1..." -Color Yellow
@"
# setup.ps1

# Stop and remove existing containers
docker stop grafana prometheus kubectl-proxy 2>`$null
docker rm grafana prometheus kubectl-proxy 2>`$null

# Remove existing images
docker rmi monitoring-stack:latest 2>`$null

# Build the Docker image
docker build -t monitoring-stack:latest .

Write-Host "Setup complete. Run 'run.ps1' to start the monitoring stack." -ForegroundColor Green
"@ | Set-Content -Path setup.ps1

# Create run.ps1
Write-Message "Creating run.ps1..." -Color Yellow
@"
# run.ps1

# Create Docker network
docker network create monitoring-network 2>`$null

# Run Grafana
docker run -d --name grafana ``
    --network monitoring-network ``
    -p 3000:3000 ``
    -v "`${PWD}/configs:/etc/grafana" ``
    monitoring-stack:latest

# Run Prometheus
docker run -d --name prometheus ``
    --network monitoring-network ``
    -p 9090:9090 ``
    -v "`${PWD}/configs/prometheus.yml:/etc/prometheus/prometheus.yml" ``
    prom/prometheus:latest

# Run kubectl-proxy
docker run -d --name kubectl-proxy ``
    --network host ``
    bitnami/kubectl:latest ``
    kubectl proxy --address 0.0.0.0 --port 8080

Write-Host "Monitoring stack is now running." -ForegroundColor Green
Write-Host "Access Grafana at http://localhost:3000" -ForegroundColor Yellow
Write-Host "Default credentials: admin / admin" -ForegroundColor Yellow
"@ | Set-Content -Path run.ps1

# Create Dockerfile
Write-Message "Creating Dockerfile..." -Color Yellow
@"
FROM grafana/grafana:latest

COPY configs/grafana.ini /etc/grafana/grafana.ini
COPY configs/provisioning /etc/grafana/provisioning
COPY configs/dashboards /var/lib/grafana/dashboards

USER root
RUN mkdir -p /etc/grafana /var/lib/grafana && \
    chown -R 472:472 /etc/grafana /var/lib/grafana
USER 472
"@ | Set-Content -Path Dockerfile

# Create prometheus.yml
Write-Message "Creating prometheus.yml..." -Color Yellow
@"
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
    - role: endpoints
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      action: keep
      regex: default;kubernetes;https

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
    - role: node
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)

  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
    - role: service
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
"@ | Set-Content -Path .\configs\prometheus.yml

# Create grafana.ini
Write-Message "Creating grafana.ini..." -Color Yellow
@"
[auth.anonymous]
enabled = true
org_role = Admin

[security]
admin_user = admin
admin_password = admin
"@ | Set-Content -Path .\configs\grafana.ini

# Create datasources.yaml
Write-Message "Creating datasources.yaml..." -Color Yellow
New-Item -ItemType Directory -Force -Path .\configs\provisioning\datasources | Out-Null
@"
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
"@ | Set-Content -Path .\configs\provisioning\datasources\datasources.yaml

# Create dashboards.yaml
Write-Message "Creating dashboards.yaml..." -Color Yellow
New-Item -ItemType Directory -Force -Path .\configs\provisioning\dashboards | Out-Null
@"
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
"@ | Set-Content -Path .\configs\provisioning\dashboards\dashboards.yaml

# Create kubernetes-overview.json
Write-Message "Creating kubernetes-overview.json..." -Color Yellow
New-Item -ItemType Directory -Force -Path .\configs\dashboards | Out-Null
@"
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": null,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.2.0",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{image!=\"\"}[5m])) by (namespace)",
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "CPU Usage by Namespace",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "schemaVersion": 26,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Kubernetes Overview",
  "uid": "kubernetes-overview",
  "version": 1
}
"@ | Set-Content -Path .\configs\dashboards\kubernetes-overview.json

Write-Message "Setup complete!" -Color Green
Write-Message "To get started:" -Color Yellow
Write-Message "1. Run './setup.ps1' to build the Docker image" -Color Yellow
Write-Message "2. Run './run.ps1' to start the monitoring stack" -Color Yellow
Write-Message "3. Access Grafana at http://localhost:3000 (admin / admin)" -Color Yellow