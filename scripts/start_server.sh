#!/bin/bash
# Starts the application using PM2 (production process manager)

set -e

echo "=== ApplicationStart: Starting application ==="

cd /home/ec2-user/app

# Pull environment variables from SSM Parameter Store
export APP_ENV=$(aws ssm get-parameter \
  --name "/cicd-demo/app/environment" \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1)

export APP_VERSION=$(cat version.txt 2>/dev/null || echo "unknown")

# Start with PM2 — keeps app alive after SSH session ends
pm2 start src/index.js \
  --name "cicd-demo-app" \
  --env production

# Save PM2 process list so it survives reboots
pm2 save

echo "=== ApplicationStart: Application started ==="
