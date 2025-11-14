# Exchange Rate Scraper

A Node.js project that scrapes exchange rates from multiple providers, deployed on AWS ECS Fargate using Terraform and GitHub Actions.

## 🚀 Quick Start

### Local Development

#### Installation

```bash
yarn install
```

#### Usage

Run all scrapers:
```bash
yarn start
# or
SCRAPERS=* yarn start
```

Run a specific scraper:
```bash
SCRAPERS=xe yarn start
```

Run multiple scrapers:
```bash
SCRAPERS=xe,wise yarn start
```

### Docker

Build and run locally:
```bash
docker build -t sc-test:latest .
docker run -e SCRAPERS=xe,wise sc-test:latest
```

Or use Docker Compose:
```bash
docker-compose up
```

## AWS Deployment

This project uses **Terraform** for infrastructure management and **GitHub Actions** for CI/CD.

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

This creates:
- ECR Repository
- ECS Cluster & Task Definition
- IAM Roles
- Security Group
- CloudWatch Logs

### 2. Setup GitHub Secrets

Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ECS_SUBNET_IDS` - Get from: `terraform output -json subnet_ids | jq -r 'join(",")'`
- `ECS_SECURITY_GROUP` - Get from: `terraform output -raw security_group_id`

### 3. Deploy Application

Push to `main` branch → GitHub Actions automatically builds and pushes to ECR

### 4. Run Tasks

Go to GitHub Actions → "Run ECS Task with Latest Image" → Choose scrapers → Run

See [`DEPLOYMENT.md`](DEPLOYMENT.md) for detailed setup instructions.
See [`terraform/README.md`](terraform/README.md) for Terraform documentation.
See [`SETUP-GUIDE.md`](SETUP-GUIDE.md) for complete walkthrough.
See [`CHEATSHEET.md`](CHEATSHEET.md) for quick reference commands.

**New to the project?** Start with [`TRANSFORMATION.md`](TRANSFORMATION.md) to understand the architecture!

## Supported Providers

- **xe** - XE.com
- **wise** - Wise (formerly TransferWise)
- **remitely** - Remitely

## Architecture

```
┌─────────────────┐
│  GitHub Actions │
│   (CI/CD)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│   AWS ECR       │◄─────┤  Terraform   │
│ (Docker Images) │      │ (IaC)        │
└────────┬────────┘      └──────────────┘
         │
         ▼
┌─────────────────┐
│   ECS Fargate   │
│   (Run Tasks)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CloudWatch     │
│  (Logs)         │
└─────────────────┘
```

## GitHub Actions Workflows

1. **`terraform.yml`** - Deploy/update AWS infrastructure
2. **`deploy.yml`** - Build and push Docker image to ECR
3. **`deploy-and-run.yml`** - Build, push, and run ECS task
4. **`run-task.yml`** - Run task with existing image

## Project Structure

```
.
├── index.js                      # Entry point
├── scrapers/
│   ├── index.js                 # Scraper exports
│   ├── xe.js                    # XE scraper
│   ├── wise.js                  # Wise scraper
│   └── remitely.js              # Remitely scraper
├── terraform/
│   ├── main.tf                  # Main infrastructure
│   ├── variables.tf             # Configuration variables
│   ├── outputs.tf               # Output values
│   └── README.md                # Terraform documentation
├── .github/workflows/
│   ├── terraform.yml            # Infrastructure deployment
│   ├── deploy.yml               # Docker build & push
│   ├── deploy-and-run.yml       # Build & run task
│   └── run-task.yml             # Run existing image
├── Dockerfile                    # Docker configuration
├── docker-compose.yml            # Local testing
├── DEPLOYMENT.md                 # Deployment guide
└── package.json
```
