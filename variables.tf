variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "project" {
  type    = string
  default = "securecart"
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