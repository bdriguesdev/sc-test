# Quick Reference Cheat Sheet

## 🚀 Quick Commands

### Initial Setup
```bash
# 1. Deploy infrastructure
cd terraform && terraform init && terraform apply

# 2. Get GitHub Secrets values
terraform output -raw security_group_id
terraform output -json subnet_ids | jq -r 'join(",")'

# 3. Add secrets to GitHub (see SETUP-GUIDE.md)

# 4. Push code to main
git push origin main
```

### Daily Use
```bash
# Run scrapers: GitHub → Actions → "Run ECS Task with Latest Image"

# Update code: 
git add . && git commit -m "Update" && git push origin main
```

## 📋 Terraform Commands

```bash
cd terraform

terraform init              # Initialize (first time only)
terraform plan              # Preview changes
terraform apply             # Create/update resources
terraform destroy           # Delete everything
terraform output            # Show all outputs
terraform output <name>     # Show specific output
terraform fmt               # Format files
terraform validate          # Check syntax
```

## 🐳 Docker Commands

```bash
# Local testing
docker build -t sc-test:latest .
docker run -e SCRAPERS=xe,wise sc-test:latest
docker-compose up

# ECR operations
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker tag sc-test:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

## ☁️ AWS ECS Commands

```bash
# Run task manually
aws ecs run-task \
  --cluster sc-test-cluster \
  --task-definition sc-test-task \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"scraper","environment":[{"name":"SCRAPERS","value":"*"}]}]}'

# List running tasks
aws ecs list-tasks --cluster sc-test-cluster

# Stop task
aws ecs stop-task --cluster sc-test-cluster --task <task-arn>

# Describe task
aws ecs describe-tasks --cluster sc-test-cluster --tasks <task-arn>
```

## 📊 Logs

```bash
# Tail logs
aws logs tail /ecs/sc-test-task --follow

# Get specific log stream
aws logs get-log-events --log-group-name /ecs/sc-test-task --log-stream-name <stream-name>
```

## 🔧 Terraform Outputs Reference

```bash
terraform output ecr_repository_url          # ECR image URL
terraform output ecs_cluster_name            # ECS cluster name
terraform output ecs_task_definition_family  # Task definition name
terraform output security_group_id           # Security group ID
terraform output subnet_ids                  # Subnet IDs (JSON array)
terraform output cloudwatch_log_group        # Log group name
```

## 🔐 GitHub Secrets Required

| Secret Name | How to Get |
|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Console |
| `ECS_SUBNET_IDS` | `terraform output -json subnet_ids \| jq -r 'join(",")'` |
| `ECS_SECURITY_GROUP` | `terraform output -raw security_group_id` |

## 🎯 GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `terraform.yml` | Push to `terraform/**` | Deploy infrastructure |
| `deploy.yml` | Push to `main` | Build & push image |
| `deploy-and-run.yml` | Manual/Push | Build & run task |
| `run-task.yml` | Manual | Run existing image |

## 🌐 Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `SCRAPERS` | `*` | Run all scrapers |
| | `xe` | Run XE only |
| | `wise` | Run Wise only |
| | `xe,wise` | Run multiple |
| | `xe,wise,remitely` | Run all three |

## 📁 Key Files

| File | Purpose |
|------|---------|
| `index.js` | Entry point - runs scrapers |
| `scrapers/*.js` | Individual scraper logic |
| `Dockerfile` | Container definition |
| `terraform/main.tf` | AWS infrastructure |
| `.github/workflows/*.yml` | CI/CD pipelines |

## 🆘 Troubleshooting Quick Fixes

```bash
# Can't authenticate to AWS
aws sts get-caller-identity
aws configure

# Terraform state issues
terraform refresh
terraform state list

# Docker login issues
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)

# GitHub Actions failing
# → Check secrets are set correctly
# → Check AWS credentials have proper permissions

# Task not starting
# → Check security group allows outbound traffic
# → Check subnets have internet access (NAT/IGW)
# → Check task execution role has ECR permissions
```

## 💰 Cost Estimates

| Usage Pattern | Monthly Cost |
|---------------|--------------|
| Run once per day (5 min) | ~$0.10 |
| Run hourly (5 min) | ~$7.00 |
| Run every 15 min (5 min) | ~$28.00 |

*Based on 256 CPU, 512 MB RAM @ $0.04048/hour*

## 🔄 Common Workflows

### Add New Scraper
```bash
# 1. Create scraper file
cat > scrapers/revolut.js << 'EOF'
function revolutScraper() {
  console.log('=== Revolut Scraper ===');
  console.log('Provider: Revolut');
  console.log('Completed\n');
}
module.exports = revolutScraper;
EOF

# 2. Export from index
# Edit scrapers/index.js to add:
# revolut: require('./revolut')

# 3. Commit and push
git add . && git commit -m "Add Revolut scraper" && git push origin main
```

### Change Task Resources
```bash
# Edit terraform/variables.tf
# Change task_cpu and task_memory defaults

# Apply changes
cd terraform && terraform apply
```

### View Real-Time Logs During Run
```bash
# Terminal 1: Start tailing logs
aws logs tail /ecs/sc-test-task --follow

# Terminal 2 or GitHub Actions: Run task
# (logs will appear in terminal 1)
```

## 📞 Support Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- Project Docs: `README.md`, `DEPLOYMENT.md`, `SETUP-GUIDE.md`, `terraform/README.md`
