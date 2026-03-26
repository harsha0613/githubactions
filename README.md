# CI/CD Template: GitHub Actions + AWS CodeBuild + CodeDeploy + EC2

This template gives you a working starting point for a pipeline that does three things:

1. runs tests
2. builds and pushes a Docker image to Amazon ECR
3. deploys that image to an EC2 instance through AWS CodeDeploy

## Architecture

- **GitHub Actions** triggers on push to `main`
- **AWS CodeBuild** acts as the GitHub Actions runner for the test/build job
- **Amazon ECR** stores the Docker image
- **AWS CodeDeploy** ships the deployment bundle to EC2
- **EC2** pulls the new image and restarts the container with Docker Compose

---

## Files included

- `.github/workflows/ci-cd.yml` → main pipeline
- `buildspec.yml` → optional CodeBuild buildspec reference
- `codedeploy/appspec.yml` → deployment instructions for CodeDeploy
- `codedeploy/scripts/*` → hook scripts run on EC2
- `docker-compose.prod.yml` → production container startup file
- `ec2/bootstrap-ec2-amazon-linux-2023.sh` → one-time EC2 setup script

---

## Before you push this repo

### 1) Create an Amazon ECR repository
Example name:

- `my-springboot-app`

### 2) Launch an EC2 instance
Use Amazon Linux 2023.
Open these ports in the security group:

- `22` for SSH
- `8080` if you want direct app access
- `80/443` later if you put Nginx in front

### 3) Attach an IAM role to EC2
The EC2 instance role should be able to:

- read from ECR
- work with CodeDeploy
- optionally read from SSM / Secrets Manager if you later store env vars there

A practical minimum is:

- `AmazonEC2ContainerRegistryReadOnly`
- `AmazonSSMManagedInstanceCore` (optional but useful)
- `AWSCodeDeployFullAccess` is **not** recommended for production; instead use a smaller custom policy or the standard CodeDeploy instance profile setup

### 4) Install Docker and CodeDeploy agent on EC2
SSH into the instance and run:

```bash
sudo bash ec2/bootstrap-ec2-amazon-linux-2023.sh
```

If your region is not `us-east-1`, edit the CodeDeploy installer URL in that script.

### 5) Create a CodeDeploy application and deployment group
Create:

- compute platform: **EC2/On-Premises**
- one deployment group pointing to your EC2 instance by tag or Auto Scaling group

### 6) Create an S3 bucket for CodeDeploy bundles
Example:

- `my-app-codedeploy-bundles`

### 7) Create a CodeBuild project to act as the GitHub Actions runner
The project name must match the GitHub variable `CODEBUILD_PROJECT`.
Use:

- source provider: GitHub
- webhook enabled
- privileged mode enabled, because Docker build needs Docker
- Linux image with Docker support

### 8) Configure GitHub OIDC in AWS
Create an IAM OIDC provider for GitHub and a role that GitHub Actions can assume.
That role should be allowed to:

- push images to ECR
- upload deployment bundles to S3
- create CodeDeploy deployments
- optionally read secrets

### 9) Add GitHub repository variables
In **GitHub → Settings → Secrets and variables → Actions → Variables**, add:

- `AWS_REGION` → example `us-east-1`
- `AWS_GITHUB_ACTIONS_ROLE_ARN` → IAM role ARN for GitHub OIDC
- `ECR_REGISTRY` → example `123456789012.dkr.ecr.us-east-1.amazonaws.com`
- `ECR_REPOSITORY` → example `my-springboot-app`
- `CODEDEPLOY_APP_NAME` → your CodeDeploy app name
- `CODEDEPLOY_DEPLOYMENT_GROUP` → your deployment group name
- `CODEDEPLOY_S3_BUCKET` → S3 bucket for bundles
- `CODEBUILD_PROJECT` → your CodeBuild project name

---

## Small edits you must make in this template

### Replace the AWS region in this file
Open:

- `codedeploy/scripts/after_install.sh`

Replace:

- `__AWS_REGION__`

with your actual region, for example:

- `us-east-1`

### Confirm your health endpoint
The deploy validation script checks:

```bash
http://localhost:8080/actuator/health
```

If your app uses a different endpoint, update:

- `codedeploy/scripts/validate_service.sh`

### Confirm your test command
The workflow currently uses:

```bash
mvn -B clean test
```

That is good for your Spring Boot app. If the project changes, update it.

---

## How deployment works

1. push to `main`
2. GitHub Actions starts
3. `test-build-push` job runs on **CodeBuild-hosted GitHub Actions runner**
4. tests run
5. Docker image is built and pushed to ECR with:
   - tag = commit SHA
   - tag = `latest`
6. `deploy` job creates a zip bundle with `appspec.yml`, deployment scripts, and the image URI
7. bundle is uploaded to S3
8. CodeDeploy sends it to EC2
9. EC2 logs into ECR, pulls the new image, and starts it with Docker Compose

---

## Commands to verify after first deployment

On EC2:

```bash
docker ps
curl http://localhost:8080/actuator/health
sudo systemctl status codedeploy-agent
```

---

## Notes

- This template is intentionally simple and good for a class project or MVP.
- For production, add Nginx, HTTPS, separate staging/prod environments, and secrets from AWS Systems Manager Parameter Store or Secrets Manager.
- If you do **not** want CodeDeploy, you can switch the deploy step to SSH into EC2 directly, but CodeDeploy is cleaner for AWS-based EC2 deployments.
