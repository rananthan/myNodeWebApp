variable "ecr_repo_name" {
  description = "Value of the ECR Repo Name"
  type        = string
  default     = "my_ecr_repo"
}
variable "ecs_cluster_name" {
  description = "Value of the ECS Cluster Name"
  type        = string
  default     = "my_ecs_cluster"
}

variable "ecs_service_name" {
  description = "Value of the ECS Cluster Name"
  type        = string
  default     = "my_ecs_service"
}