# Terraform Infrastructure Management

This project uses Terraform to manage AWS infrastructure for the scraper application.

## Prerequisites

1. **Install Terraform:**
   ```bash
   # On Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Or on macOS
   brew install terraform
   ```

2. **Configure AWS Credentials:**
   ```bash
   aws configure
   # Or export credentials
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

## Quick Start

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Apply Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### 4. View Outputs
```bash
terraform output
```

This will show:
- ECR Repository URL
- ECS Cluster name
- Task Definition ARN
- Security Group ID
- Subnet IDs
- CloudWatch Log Group

## What Terraform Creates

- **ECR Repository** - Docker image storage
- **ECS Cluster** - Container orchestration
- **ECS Task Definition** - Container configuration
- **CloudWatch Log Group** - Application logs
- **IAM Roles** - Execution and task permissions
- **Security Group** - Network access control

## Configuration

Edit `terraform/variables.tf` or create a `terraform/terraform.tfvars` file:

```hcl
aws_region          = "us-east-1"
environment         = "production"
task_cpu            = "512"
task_memory         = "1024"
log_retention_days  = 30
```

## GitHub Actions Integration

The `.github/workflows/terraform.yml` workflow:
- Runs on pushes to `terraform/` directory
- Can be manually triggered
- Automatically applies infrastructure changes

**Required GitHub Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## After Infrastructure is Created

### Update GitHub Secrets

After running Terraform, update your GitHub repository secrets:

```bash
# Get the security group ID
terraform output -raw security_group_id

# Get subnet IDs (comma-separated)
terraform output -json subnet_ids | jq -r 'join(",")'
```

Add to GitHub Secrets:
- `ECS_SECURITY_GROUP` = (security group ID from above)
- `ECS_SUBNET_IDS` = (subnet IDs from above)

### Deploy Your Application

1. **Build and push Docker image:**
   ```bash
   # Get ECR URL
   ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
   
   # Build and push
   docker build -t $ECR_URL:latest .
   docker push $ECR_URL:latest
   ```

2. **Run the task:**
   ```bash
   # Use the run-task.yml workflow or:
   aws ecs run-task \
     --cluster $(cd terraform && terraform output -raw ecs_cluster_name) \
     --task-definition $(cd terraform && terraform output -raw ecs_task_definition_family) \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[$(cd terraform && terraform output -json subnet_ids | jq -r '.[0]')],securityGroups=[$(cd terraform && terraform output -raw security_group_id)],assignPublicIp=ENABLED}"
   ```

## Updating Infrastructure

1. Modify Terraform files in `terraform/` directory
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes
4. Or push to `main` branch and let GitHub Actions apply automatically

## Destroying Infrastructure

⚠️ **Warning:** This will delete all resources!

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

## Common Commands

```bash
# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output ecr_repository_url

# Refresh state
terraform refresh
```

## Troubleshooting

**Issue: State lock error**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

**Issue: Resources already exist**
```bash
# Import existing resources
terraform import aws_ecr_repository.sc_test sc-test
```

**Issue: Drift detection**
```bash
# Check if infrastructure matches state
terraform plan -refresh-only
```

## State Management (Production)

For production, use remote state storage:

1. Create S3 bucket for state:
   ```bash
   aws s3 mb s3://your-terraform-state-bucket
   aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
   ```

2. Uncomment the backend configuration in `terraform/main.tf`:
   ```hcl
   backend "s3" {
     bucket = "your-terraform-state-bucket"
     key    = "sc-test/terraform.tfstate"
     region = "us-east-1"
   }
   ```

3. Reinitialize:
   ```bash
   terraform init -migrate-state
   ```

## Cost Estimation

Free tier eligible resources:
- ECR: 500 MB storage/month
- CloudWatch: 5 GB logs/month
- ECS Fargate: Pay per second of task execution

Estimated cost (minimal usage):
- ~$0.01-0.10/month for storage
- Task execution: ~$0.04/hour (256 CPU, 512 MB)
