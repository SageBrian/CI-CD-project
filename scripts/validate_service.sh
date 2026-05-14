#!/bin/bash
# Validates the deployment succeeded by hitting the health endpoint

set -e

echo "=== ValidateService: Checking application health ==="

# Give the app a moment to start
sleep 5

# Hit the health endpoint — if it returns 200, deployment is good
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "=== ValidateService: Health check passed (HTTP $HTTP_STATUS) ==="
  exit 0
else
  echo "=== ValidateService: Health check FAILED (HTTP $HTTP_STATUS) ==="
  exit 1  # Non-zero exit causes CodeDeploy to roll back
fi
