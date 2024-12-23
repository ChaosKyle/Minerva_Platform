# Define the URLs for Loki, Prometheus, and Mimir services
$lokiUrl = "http://localhost:3100"
$prometheusUrl = "http://localhost:9090"
$mimirUrl = "http://localhost:7201"

# Define the Grafana Alloy Agent configuration
$grafanaAgentConfig = @"
server:
  log_level: info

metrics:
  wal_directory: /tmp/grafana-agent-wal
  global:
    scrape_interval: 15s
    external_labels:
      cluster: "local"
  configs:
    - name: default
      scrape_configs:
        - job_name: 'prometheus'
          static_configs:
            - targets: ['$prometheusUrl']
      remote_write:
        - url: '$mimirUrl/api/v1/push'

logs:
  positions_directory: /tmp/grafana-agent-positions
  configs:
    - name: default
      clients:
        - url: '$lokiUrl/loki/api/v1/push'
      target_config:
        sync_period: 10s
      positions:
        filename: /tmp/positions.yaml
      scrape_configs:
        - job_name: 'varlogs'
          static_configs:
            - targets:
                - localhost
              labels:
                job: varlogs
                __path__: /var/log/*log
"@

# Write the configuration to a file
$configFilePath = "C:\grafana-agent-config.yaml"
Set-Content -Path $configFilePath -Value $grafanaAgentConfig

# Command to start the Grafana Alloy Agent with the configuration file
$grafanaAgentCommand = "grafana-agent --config.file=$configFilePath"

# Execute the command to start the Grafana Alloy Agent
Invoke-Expression $grafanaAgentCommand
