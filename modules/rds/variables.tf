variable "project" {
  type        = string
  description = "The name of the project"
}

variable "private_subnet_a_id" {
  type        = string
  description = "Passed from root into the RDS module"
}

variable "private_subnet_b_id" {
  type        = string
  description = "Passed from root into the RDS module"
}

variable "db_security_group_id" {
  type        = string
  description = "The database security group ID passed down from the root module context"
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}
