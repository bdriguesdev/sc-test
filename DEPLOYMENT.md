# GitHub Actions AWS Deployment Setup

This project uses **Terraform** to manage AWS infrastructure and **GitHub Actions** for CI/CD.

## Prerequisites

### 1. Install Terraform (Local Development)

```bash
# On Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# On macOS
brew install terraform

# Verify installation
terraform --version
```

### 2. Setup AWS Infrastructure with Terraform

#### Option A: Using Terraform Locally

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create all AWS resources
terraform apply
```

Type `yes` when prompted. This creates:
- ECR Repository
- ECS Cluster
- ECS Task Definition
- CloudWatch Log Group
- IAM Roles
- Security Group

#### Option B: Using GitHub Actions (Automated)

Push to the `main` branch with changes to `terraform/` directory, or manually trigger the "Deploy Infrastructure with Terraform" workflow.

### 3. Get Infrastructure Outputs

After Terraform creates the resources:

```bash
cd terraform

# View all outputs
terraform output

# Get specific values for GitHub Secrets
terraform output -raw security_group_id
terraform output -json subnet_ids | jq -r 'join(",")'
terraform output -raw ecr_repository_url
```

### 4. GitHub Secrets Configuration

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

**Required Secrets:**
- `AWS_ACCESS_KEY_ID` - Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret access key

**Required for deploy-and-run.yml and run-task.yml workflows:**
- `ECS_SUBNET_IDS` - Get from: `terraform output -json subnet_ids | jq -r 'join(",")'`
- `ECS_SECURITY_GROUP` - Get from: `terraform output -raw security_group_id`

**Note:** Terraform creates these resources, so get the values from Terraform outputs!

## Available Workflows

### 1. terraform.yml - Deploy Infrastructure
**Purpose:** Creates/updates AWS infrastructure using Terraform

**Triggers:**
- Push to `main` branch with changes to `terraform/` directory
- Manual trigger via GitHub Actions UI

**What it does:**
- Runs `terraform init`, `plan`, and `apply`
- Creates all AWS resources (ECR, ECS, IAM, etc.)
- Outputs infrastructure details

### 2. deploy.yml - Build and Push Only
**Purpose:** Builds the Docker image and pushes it to ECR (doesn't run the task)

**Triggers:**
- Push to `main` branch (excluding `terraform/` changes)
- Manual trigger via GitHub Actions UI

**What it does:**
- Builds Docker image
- Pushes to ECR with commit SHA tag and `latest` tag

### 3. deploy-and-run.yml - Build, Deploy, and Run
**Purpose:** Builds the Docker image, pushes to ECR, and runs an ECS Fargate task

**Triggers:**
- Push to `main` branch
- Manual trigger with optional `scrapers` input

**What it does:**
- Builds and pushes Docker image to ECR
- Updates ECS task definition with new image
- Runs an ECS Fargate task with specified scrapers

**Manual Run:**
Go to Actions → "Build, Deploy, and Run ECS Task" → "Run workflow"
- You can specify which scrapers to run (default: `*`)

### 4. run-task.yml - Run Task Only ⭐ NEW
**Purpose:** Runs existing ECR image on ECS Fargate (no build required)

**Triggers:**
- Manual trigger only

**What it does:**
- Uses the latest ECR image
- Spins up an ECS Fargate task
- Allows customization of which scrapers to run

**Manual Run:**
Go to Actions → "Run ECS Task with Latest Image" → "Run workflow"
- Specify scrapers (e.g., `xe,wise`)

## Complete Setup Flow

### Initial Setup (One-time):

1. **Deploy Infrastructure with Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

2. **Get Terraform Outputs:**
   ```bash
   terraform output -raw security_group_id
   terraform output -json subnet_ids | jq -r 'join(",")'
   ```

3. **Add GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `ECS_SUBNET_IDS` (from terraform output)
   - `ECS_SECURITY_GROUP` (from terraform output)

4. **Build and Deploy First Image:**
   ```bash
   # Get ECR URL
   ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
   
   # Build and push
   docker build -t $ECR_URL:latest .
   docker push $ECR_URL:latest
   ```
   
   Or trigger the `deploy.yml` workflow.

### Daily Usage:

1. **Update Code** → Push to `main` → `deploy.yml` runs automatically
2. **Run Scrapers** → Trigger `run-task.yml` manually with desired scrapers

## Usage Examples

### Automatic Deployment
Push to `main` branch triggers automatic build and deployment:
```bash
git add .
git commit -m "Update scrapers"
git push origin main
```

### Manual Deployment with Specific Scrapers
1. Go to GitHub → Actions → "Build, Deploy, and Run ECS Task"
2. Click "Run workflow"
3. Enter scrapers (e.g., `xe,wise`)
4. Click "Run workflow"

### Run ECS Task Manually (after image is deployed)
```bash
aws ecs run-task \
  --cluster sc-test-cluster \
  --task-definition sc-test-task \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"scraper","environment":[{"name":"SCRAPERS","value":"xe,wise"}]}]}'
```

## Monitoring

### View ECS Task Logs
```bash
# Get task ARN
aws ecs list-tasks --cluster sc-test-cluster

# View logs in CloudWatch
aws logs tail /ecs/sc-test --follow
```

### View Workflow Runs
Go to your GitHub repository → Actions tab to see workflow execution history and logs.

## Cost Optimization

Since this is a one-time task runner (not a long-running service):
- Use Fargate Spot for cost savings (70% cheaper)
- Tasks will automatically stop when script completes
- Only pay for execution time

## Troubleshooting

**Issue: Task fails to start**
- Check security group allows outbound internet access
- Verify subnets have internet gateway or NAT gateway
- Check task execution role has ECR pull permissions

**Issue: GitHub Actions fails at AWS step**
- Verify AWS credentials are correctly set in GitHub Secrets
- Check IAM permissions for ECR, ECS operations

**Issue: Can't see logs**
- Ensure CloudWatch log group exists
- Verify task execution role has CloudWatch Logs permissions
