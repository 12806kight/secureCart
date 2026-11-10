output "app_sg_id" {
  description = "The ID of the application tier security group"
  value       = aws_security_group.SCapp_sg.id # <-- FIXED: Match your resource label
}

output "alb_sg_id" {
  description = "The ID of the public load balancer security group"
  value       = aws_security_group.alb_sg.id
}

output "db_sg_id" {
  description = "The ID of the isolated database security group"
  value       = aws_security_group.rds_sg.id
}
