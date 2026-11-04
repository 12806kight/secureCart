variable "project" {
  type    = string
  default = "securecart"
}

variable "alb_arn" {
  type        = string
  description = "The ARN of the Application Load Balancer to attach the WAF to"
}
