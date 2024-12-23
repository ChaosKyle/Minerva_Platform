# Define the necessary Kubernetes manifests
$namespaceYaml = @"
apiVersion: v1
kind: Namespace
metadata:
  name: grafana-agent
"@

$configMapYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-agent-config
  namespace: grafana-agent
data:
  agent.yaml: |
    server:
      log_level: info
      http_listen_port: 12345

    prometheus:
      wal_directory: /tmp/grafana-agent-wal
      global:
        scrape_interval: 15s
        scrape_timeout: 10s
      configs:
        - name: integrations
          scrape_configs:
            - job_name: 'prometheus'
              static_configs:
                - targets: ['localhost:9090']
            - job_name: 'loki'
              static_configs:
                - targets: ['localhost:3100']
            - job_name: 'tempo'
              static_configs:
                - targets: ['localhost:3200']
          remote_write:
            - url: http://localhost:9090/api/v1/write

    logs:
      positions_directory: /tmp/grafana-agent-positions
      configs:
        - name: integrations
          clients:
            - url: http://localhost:3100/loki/api/v1/push
            - url: http://localhost:3100/mimir/api/v1/push
          positions:
            filename: /tmp/positions.yaml
          scrape_configs:
            - job_name: varlogs
              static_configs:
                - targets:
                    - localhost
                  labels:
                    job: varlogs
                    __path__: /var/log/**/*.log

    traces:
      configs:
        - name: integrations
          receivers:
            otlp:
              protocols:
                grpc:
                  endpoint: "0.0.0.0:4317"
                http:
                  endpoint: "0.0.0.0:4318"
          remote_write:
            - endpoint: "http://localhost:3200/api/traces"
"@

$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-agent
  namespace: grafana-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-agent
  template:
    metadata:
      labels:
        app: grafana-agent
    spec:
      containers:
        - name: grafana-agent
          image: grafana/agent:v0.22.0
          args:
            - --config.file=/etc/grafana-agent/agent.yaml
          volumeMounts:
            - name: grafana-agent-config
              mountPath: /etc/grafana-agent
      volumes:
        - name: grafana-agent-config
          configMap:
            name: grafana-agent-config
"@

# Save the manifests to temporary files
$namespaceFile = "namespace.yaml"
$configMapFile = "grafana-agent-config.yaml"
$deploymentFile = "grafana-agent-deployment.yaml"

$namespaceYaml | Out-File -FilePath $namespaceFile -Encoding UTF8
$configMapYaml | Out-File -FilePath $configMapFile -Encoding UTF8
$deploymentYaml | Out-File -FilePath $deploymentFile -Encoding UTF8

# Apply the manifests to the Kubernetes cluster
Write-Host "Creating namespace..."
kubectl apply -f $namespaceFile

Write-Host "Creating ConfigMap..."
kubectl apply -f $configMapFile

Write-Host "Deploying Grafana Agent..."
kubectl apply -f $deploymentFile

# Clean up the temporary files
Remove-Item $namespaceFile, $configMapFile, $deploymentFile

# Verify the deployment
Write-Host "Verifying deployment..."
kubectl get pods -n grafana-agent

Write-Host "Grafana Agent setup completed."
