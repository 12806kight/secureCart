variable "project" {
  type        = string
  description = "The name of the project"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID passed from the root main.tf"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block passed from the VPC module"
}
