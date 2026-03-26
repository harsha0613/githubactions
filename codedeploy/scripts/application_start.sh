#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/app-deploy"
cd "$APP_DIR"

/usr/bin/docker compose -f docker-compose.prod.yml pull
/usr/bin/docker compose -f docker-compose.prod.yml up -d --remove-orphans
