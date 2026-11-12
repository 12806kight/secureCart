variable "project" {
  type    = string
  default = "securecart"
}

variable "alb_arn" {
  type        = string
  description = "The ARN of the Application Load Balancer to attach the WAF to"
}

variable "enable_waf" {
  type        = bool
  description = "Toggle to deploy AWS WAF (Note: WAF is not included in AWS Free Tier)"
  default     = false
}
