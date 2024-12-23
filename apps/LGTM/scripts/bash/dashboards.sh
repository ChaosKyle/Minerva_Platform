#!/bin/bash

# Variables
S3_BUCKET="dev-grafana-bucket "
S3_KEY="dashboards/dashboard_-FSFvQ9Sz.json"
GRAFANA_URL="https://grafana.dev.data.trddev.io"
SERVICE_ACCOUNT_NAME="grafana-service-account"
API_KEY_NAME="dashboard-import"
API_KEY_TTL="1h"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Function to create a Grafana service account
create_service_account() {
    local service_account_response
    service_account_response=$(curl -s -X POST "$GRAFANA_URL/api/serviceaccounts" \
        -H "Content-Type: application/json" \
        -u "$ADMIN_USER:$ADMIN_PASSWORD" \
        -d '{
            "name": "'"$SERVICE_ACCOUNT_NAME"'",
            "role": "Admin"
        }')
    echo $(echo $service_account_response | jq -r '.id')
}

# Function to create a Grafana API key
create_api_key() {
    local api_key_response
    api_key_response=$(curl -s -X POST "$GRAFANA_URL/api/auth/keys" \
        -H "Content-Type: application/json" \
        -u "$ADMIN_USER:$ADMIN_PASSWORD" \
        -d '{
            "name": "'"$API_KEY_NAME"'",
            "role": "Admin",
            "secondsToLive": 3600
        }')
    echo $(echo $api_key_response | jq -r '.key')
}

# Create the service account
SERVICE_ACCOUNT_ID=$(create_service_account)
if [ -z "$SERVICE_ACCOUNT_ID" ]; then
    echo "Failed to create service account"
    exit 1
fi

# Create a temporary API key
API_KEY=$(create_api_key)
if [ -z "$API_KEY" ]; then
    echo "Failed to create API key"
    exit 1
fi

# Download the dashboard JSON from S3
aws s3 cp "s3://$S3_BUCKET/$S3_KEY" dashboard.json
if [ $? -ne 0 ]; then
    echo "Failed to download dashboard JSON from S3"
    exit 1
fi

# Import the dashboard into Grafana
response=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d @dashboard.json)

if echo "$response" | grep -q '"status":"success"'; then
    echo "Dashboard imported successfully"
else
    echo "Failed to import dashboard"
    echo "Response: $response"
    exit 1
fi

# Clean up
rm dashboard.json
