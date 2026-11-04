output "db_sg_id" {
  description = "The isolated ID of the database security group container"
  value       = aws_security_group.db_sg.id
}

output "app_sg_id" {
  description = "Exposes the app server security group container ID"
  value       = aws_security_group.app_sg.id
}

output "alb_sg_id" {
    description = "Exposes the ALB Security Group"
    value = aws_security_group.alb_sg.id
}