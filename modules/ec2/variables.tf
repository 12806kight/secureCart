variable "project" {
  type        = string
  default     = "securecart"
}

variable "vpc_id" {
  type        = string
  description = "The target VPC ID"
}

variable "app_security_group_id" {
  type        = string
  description = "The security group ID for the application servers"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where the ASG will deploy instances"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro" # Free Tier friendly
}
