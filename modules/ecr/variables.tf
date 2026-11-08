variable "project" {
  type        = string
  description = "Project name prefix used for resource naming"
}

variable "environment" {
  type        = string
  description = "Deployment environment name"
  default     = "development"
}
