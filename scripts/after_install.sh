#!/bin/bash
# Runs after files are copied — install dependencies

set -e

echo "=== AfterInstall: Installing app dependencies ==="

cd /home/ec2-user/app

# Install only production dependencies
npm ci --omit=dev

echo "=== AfterInstall: Complete ==="
