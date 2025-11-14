output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.sc_test.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.sc_test.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.sc_test.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.sc_test.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.sc_test.arn
}

output "ecs_task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.sc_test.family
}

output "security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = data.aws_subnets.default.ids
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.sc_test.name
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.ecs_task.arn
}
