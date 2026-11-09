variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "project" {
  type    = string
  default = "securecart"
}



variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}