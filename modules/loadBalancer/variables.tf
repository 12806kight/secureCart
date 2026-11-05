variable "project" {
  type = string
  default = "secureCart"
}

variable "vpc_id" {
  type = string
  description = "The target VPC"
}

variable "alb_security_group_id" {
  type = string
  description = "SG ID Loadbalander"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs where the ALB will be deployed"
}

variable "certificate_arn" { type = string }

