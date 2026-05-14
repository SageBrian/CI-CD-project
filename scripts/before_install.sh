#!/bin/bash
# Runs as root before new app version is installed
# Stops the existing app if running

set -e  # Exit immediately if a command fails

echo "=== BeforeInstall: Stopping existing application ==="

# Stop the app if it's running via PM2 (process manager)
if command -v pm2 &> /dev/null; then
  pm2 stop cicd-demo-app || true  # || true so it doesn't fail if app isn't running
  pm2 delete cicd-demo-app || true
fi

# Clean up old deployment if exists
if [ -d /home/ec2-user/app ]; then
  rm -rf /home/ec2-user/app
fi

echo "=== BeforeInstall: Complete ==="
