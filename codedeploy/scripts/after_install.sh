#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/app-deploy"
AWS_REGION="us-east-1"

cd "$APP_DIR"
chown -R ec2-user:ec2-user "$APP_DIR"
chmod +x scripts/*.sh

IMAGE_URI=$(cat "$APP_DIR/IMAGE_URI")
AWS_ACCOUNT_ID=$(echo "$IMAGE_URI" | cut -d'.' -f1)
ECR_REGISTRY=$(echo "$IMAGE_URI" | cut -d'/' -f1)

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

cat > "$APP_DIR/.env" <<EOF
IMAGE_URI=$IMAGE_URI
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
EOF

# Add any extra runtime secrets manually on EC2 or pull them from SSM/Secrets Manager.
