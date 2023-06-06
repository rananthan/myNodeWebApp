output "ecr_repo_name" {
  description = "Name of the ECR Repository"
  value       = aws_ecr_repository.my_ecr_repo.name
}
output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.my_ecs_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.my_first_service.name
}

output "container_image" {
  description = "Name of the Container Image"
  value       = aws_ecr_repository.my_ecr_repo.repository_url
}

output "aws_alb" {
  description = "Name of the alb"
  value       = aws_alb.application_load_balancer.name
}