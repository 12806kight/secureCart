resource "aws_ssm_parameter" "db_host" {
  name        = "/securecart/dev/db_host"
  type        = "String"
  value       = aws_db_instance.rds_instance_TS.address # Directly captures the database endpoint
  description = "SecureCart database endpoint string"
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/securecart/db/username"
  type        = "String"
  
  # GOLD STANDARD: Pulls the value dynamically from the active RDS resource metadata.
  # No plaintext credential strings live in your code or your Git repository!
  value       = aws_db_instance.rds_instance_TS.username
  
  description = "The database administrator master username"

  tags = {
    Environment = "development"
    Project     = var.project
  }
}

resource "aws_ssm_parameter" "db_pass" {
  name        = "/securecart/db/password_secret_arn"
  type        = "String" # Storing the Secret ARN tracking string
  
  # CHANGED: Instead of passing a raw password value, store the 
  # AWS Secrets Manager ARN where your applications can fetch it.
  value       = aws_db_instance.rds_instance_TS.master_user_secret[0].secret_arn
  description = "The ARN of the AWS Secrets Manager container holding the generated DB password"

  tags = {
    Environment = "development"
    Project     = var.project
  }
}
