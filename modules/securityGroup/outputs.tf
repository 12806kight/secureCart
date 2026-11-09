output "alb_sg_id" {
  description = "The ID of the Application Load Balancer security group"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "The ID of the application server security group"
  value       = aws_security_group.SCapp_sg.id # Updated to match main.tf resource name
}

output "db_sg_id" {
  description = "The ID of the database tier security group"
  value       = aws_security_group.rds_sg.id # Updated to match main.tf resource name
}

