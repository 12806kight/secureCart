variable "project" {
  type        = string
  description = "Project name tag prefix"
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the Application Load Balancer to use as the origin"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate (Must be created in us-east-1)"
}

variable "cloudfront_secret_token" {
  type        = string
  description = "Custom secret token injected into the header to authenticate traffic at the ALB"
  sensitive   = true
}
