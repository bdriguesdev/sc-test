variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "sc-test"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "sc-test-cluster"
}

variable "ecs_task_family" {
  description = "ECS task definition family name"
  type        = string
  default     = "sc-test-task"
}

variable "container_name" {
  description = "Name of the container in task definition"
  type        = string
  default     = "scraper"
}

variable "task_cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "512"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
