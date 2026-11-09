resource "aws_ssm_parameter" "db_host" {
  name        = "/securecart/dev/db_host"
  type        = "String"
  value       = aws_db_instance.rds_instance_TS.address # Directly captures the database endpoint
  description = "SecureCart database endpoint string"
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/securecart/dev/db_user"
  type        = "String"
  value       = var.db_username
  description = "SecureCart database administrative username"
}

resource "aws_ssm_parameter" "db_pass" {
  name        = "/securecart/dev/db_password"
  type        = "SecureString" # Encrypts the password natively using AWS KMS for free
  description = "SecureCart database administrative password"
}
