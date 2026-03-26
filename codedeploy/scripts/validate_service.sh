#!/bin/bash
set -euo pipefail

APP_PORT="8080"
HEALTH_ENDPOINT="http://localhost:${APP_PORT}/actuator/health"

for i in {1..20}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" || true)
  if [ "$STATUS" = "200" ]; then
    echo "Application is healthy"
    exit 0
  fi
  echo "Waiting for app to become healthy... attempt $i"
  sleep 10
done

echo "Application failed health check"
exit 1
