# SC-Test Infrastructure Setup Summary

## What We've Built

Your project now uses **Infrastructure as Code (IaC)** with Terraform to manage all AWS resources. Here's how everything works together:

## File Structure

```
sc-test/
├── App Code (Node.js)
│   ├── index.js                    # Entry point - runs scrapers based on env var
│   ├── scrapers/
│   │   ├── xe.js                   # XE scraper
│   │   ├── wise.js                 # Wise scraper
│   │   └── remitely.js             # Remitely scraper
│   └── package.json
│
├── Docker
│   ├── Dockerfile                  # Container definition
│   └── docker-compose.yml          # Local testing
│
├── Infrastructure (Terraform)
│   ├── main.tf                     # AWS resources (ECR, ECS, IAM, etc.)
│   ├── variables.tf                # Configuration variables
│   ├── outputs.tf                  # Export values (URLs, IDs, etc.)
│   └── README.md                   # Terraform docs
│
└── CI/CD (GitHub Actions)
    ├── terraform.yml               # Deploy infrastructure
    ├── deploy.yml                  # Build & push Docker image
    ├── deploy-and-run.yml          # Build & run task
    └── run-task.yml                # Run task only
```

## AWS Resources Created by Terraform

| Resource | Purpose |
|----------|---------|
| **ECR Repository** | Stores Docker images |
| **ECS Cluster** | Orchestrates containers |
| **ECS Task Definition** | Defines how to run container |
| **CloudWatch Log Group** | Collects application logs |
| **IAM Execution Role** | Allows ECS to pull images |
| **IAM Task Role** | Runtime permissions for app |
| **Security Group** | Controls network access |

## Complete Workflow

### 1. Initial Setup (One-Time)

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 2. Get values for GitHub Secrets
terraform output -raw security_group_id           # → ECS_SECURITY_GROUP
terraform output -json subnet_ids | jq -r 'join(",")'  # → ECS_SUBNET_IDS
```

### 2. Add GitHub Secrets

Go to: Repository → Settings → Secrets and variables → Actions

Add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ECS_SUBNET_IDS` (from terraform output)
- `ECS_SECURITY_GROUP` (from terraform output)

### 3. Deploy Application

**Option A: Automatic (recommended)**
```bash
git add .
git commit -m "Initial commit"
git push origin main
```
→ `deploy.yml` workflow runs automatically

**Option B: Manual**
```bash
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest
```

### 4. Run Scrapers

Go to: GitHub → Actions → "Run ECS Task with Latest Image" → Run workflow

Or via CLI:
```bash
aws ecs run-task \
  --cluster $(cd terraform && terraform output -raw ecs_cluster_name) \
  --task-definition $(cd terraform && terraform output -raw ecs_task_definition_family) \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$(cd terraform && terraform output -json subnet_ids | jq -r '.[0]')],securityGroups=[$(cd terraform && terraform output -raw security_group_id)],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"scraper","environment":[{"name":"SCRAPERS","value":"xe,wise"}]}]}'
```

## Daily Development Workflow

### Code Changes
```bash
# 1. Make changes to scraper code
vim scrapers/xe.js

# 2. Commit and push
git add .
git commit -m "Update XE scraper"
git push origin main
```
→ GitHub Actions automatically builds and pushes new image to ECR

### Run Scrapers
1. Go to GitHub Actions tab
2. Click "Run ECS Task with Latest Image"
3. Choose scrapers to run (e.g., `xe,wise`)
4. Click "Run workflow"

### Infrastructure Changes
```bash
# 1. Update Terraform files
vim terraform/main.tf

# 2. Preview changes
cd terraform
terraform plan

# 3. Apply changes
terraform apply
```
→ Or push to `main` and let GitHub Actions apply

## How GitHub Actions Workflows Work

### terraform.yml
- **Triggers:** Push to `main` with `terraform/` changes
- **Does:** Runs `terraform apply` to create/update infrastructure
- **Use when:** Adding new AWS resources or updating config

### deploy.yml
- **Triggers:** Push to `main` (excluding terraform changes)
- **Does:** Builds Docker image and pushes to ECR
- **Use when:** You updated app code

### deploy-and-run.yml
- **Triggers:** Manual or push to `main`
- **Does:** Builds, pushes, AND runs task
- **Use when:** You want to build and immediately run

### run-task.yml ⭐ MOST USED
- **Triggers:** Manual only
- **Does:** Runs existing ECR image on ECS Fargate
- **Use when:** You want to run scrapers with existing image

## Terraform vs Manual Setup

### Before (Manual):
```bash
# Create each resource manually
aws ecr create-repository --repository-name sc-test
aws ecs create-cluster --cluster-name sc-test-cluster
aws logs create-log-group --log-group-name /ecs/sc-test
# ... plus IAM roles, security groups, task definitions...
```
❌ Hard to track what exists
❌ Hard to replicate
❌ Manual updates
❌ No version control

### After (Terraform):
```bash
terraform apply
```
✅ One command creates everything
✅ Version controlled (Git)
✅ Easy to replicate (dev/staging/prod)
✅ Tracks state automatically
✅ Can destroy and recreate easily

## Cost Breakdown

### Free Tier Eligible:
- ECR: 500 MB storage/month (free forever)
- CloudWatch: 5 GB logs/month (free tier)
- VPC/Security Groups: Free

### Pay-As-You-Go:
- **ECS Fargate:** ~$0.04/hour for 256 CPU, 512 MB RAM
- **Example:** Running scrapers for 5 minutes = ~$0.003 (less than a penny!)

### Estimated Monthly Cost:
- **Light usage** (run once daily, 5 min each): ~$0.10/month
- **Heavy usage** (run hourly, 5 min each): ~$7/month

## Viewing Logs

### Via AWS Console:
1. Go to CloudWatch → Log groups
2. Find `/ecs/sc-test-task`
3. View log streams

### Via CLI:
```bash
aws logs tail /ecs/sc-test-task --follow
```

### Via GitHub Actions:
Logs are shown in the workflow run output

## Troubleshooting

### Issue: Terraform fails to create resources
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check region
aws configure get region
```

### Issue: GitHub Actions can't find subnets/security group
- Ensure you added `ECS_SUBNET_IDS` and `ECS_SECURITY_GROUP` secrets
- Get values from: `cd terraform && terraform output`

### Issue: Task fails to start
```bash
# Check task events
aws ecs describe-tasks --cluster sc-test-cluster --tasks <task-arn>

# Check logs
aws logs tail /ecs/sc-test-task --follow
```

### Issue: Can't push to ECR
```bash
# Re-authenticate
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
```

## Cleanup

### Destroy Everything:
```bash
cd terraform
terraform destroy
```

This removes ALL AWS resources created by Terraform (ECR, ECS, logs, etc.)

⚠️ **Warning:** This is irreversible! Make sure you have backups of any important data.

## Next Steps

### Add More Scrapers
1. Create new file in `scrapers/` (e.g., `revolut.js`)
2. Export from `scrapers/index.js`
3. Push to `main`
4. Run with `SCRAPERS=revolut`

### Schedule Periodic Runs
Use AWS EventBridge (CloudWatch Events) to run tasks on a schedule:
```bash
# Run daily at 9 AM
aws events put-rule --schedule-expression "cron(0 9 * * ? *)" --name daily-scraper
aws events put-targets --rule daily-scraper --targets "Id"="1","Arn"="<cluster-arn>","RoleArn"="<role-arn>","EcsParameters"="{TaskDefinitionArn=<task-def-arn>,LaunchType=FARGATE}"
```

### Add Different Environments
Create separate `.tfvars` files:
```bash
# terraform/prod.tfvars
environment = "production"
task_cpu = "512"
task_memory = "1024"

# Apply with
terraform apply -var-file="prod.tfvars"
```

## Summary

✅ **Infrastructure:** Managed by Terraform (version controlled, repeatable)
✅ **CI/CD:** Automated with GitHub Actions
✅ **Deployment:** Push to main → Auto-deploy
✅ **Execution:** One-click task runs
✅ **Cost:** Pay only for execution time (~pennies)
✅ **Scalable:** Easy to add more scrapers or environments

You now have a production-ready, cloud-native scraping platform! 🚀
