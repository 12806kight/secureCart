variable "project" {
  type    = string
  default = "secureCart"
}

variable "vpc_id" {
  type        = string
  description = "The target VPC"
}

variable "alb_security_group_id" {
  type        = string
  description = "SG ID Loadbalancer"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs where the ALB will be deployed"
}

variable "certificate_arn" {
  type = string
}

variable "cloudfront_secret_token" {
  type        = string
  description = "Secret header value sent by CloudFront to authenticate origin requests"
  sensitive   = true
}

variable "alb_logs_bucket_id" {
  type        = string
  description = "S3 bucket ID for storing ALB access logs"
}
