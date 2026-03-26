#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/app-deploy"
mkdir -p "$APP_DIR"
chown -R ec2-user:ec2-user "$APP_DIR"

if [ -f "$APP_DIR/docker-compose.prod.yml" ]; then
  cd "$APP_DIR"
  /usr/bin/docker compose down || true
fi
