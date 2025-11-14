terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-bdrigues"
    key    = "sc-test/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR Repository
resource "aws_ecr_repository" "sc_test" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "sc-test"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECR Lifecycle Policy - Keep only last 10 images
resource "aws_ecr_lifecycle_policy" "sc_test" {
  repository = aws_ecr_repository.sc_test.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "sc_test" {
  name              = "/ecs/${var.ecs_task_family}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "sc-test-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "sc_test" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "sc-test-cluster"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.ecs_cluster_name}-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.ecs_cluster_name}-tasks-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.ecs_task_family}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.ecs_task_family}-execution-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (runtime permissions)
resource "aws_iam_role" "ecs_task" {
  name = "${var.ecs_task_family}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.ecs_task_family}-task-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "sc_test" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = "${aws_ecr_repository.sc_test.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "SCRAPERS"
        value = "*"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.sc_test.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name        = var.ecs_task_family
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
