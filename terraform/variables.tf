variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloud-incident"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name the backend connects to"
  type        = string
  default     = "postgres"
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the backend image"
  type        = string
  default     = "351291606284.dkr.ecr.eu-west-3.amazonaws.com"
}