#!/bin/bash
set -euo pipefail

# Run this on a fresh Amazon Linux 2023 EC2 instance as root.

dnf update -y

dnf install -y docker ruby wget unzip
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

mkdir -p /home/ec2-user/app-deploy
chown -R ec2-user:ec2-user /home/ec2-user/app-deploy
