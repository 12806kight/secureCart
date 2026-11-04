output "target_group_arn" {
  description = "The ARN of the ALB target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "alb_dns_name" {
  description = "The public DNS name of the load balancer"
  value       = aws_lb.securecart_alb.dns_name
}

output "alb_arn" {
  description = "The ARN of the application load balancer"
  value       = aws_lb.securecart_alb.arn
}
