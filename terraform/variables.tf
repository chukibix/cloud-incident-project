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
