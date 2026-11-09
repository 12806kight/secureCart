resource "aws_db_subnet_group" "this" {
  name        = "${var.project}-rds-subnet-group"
  description = "Isolated private subnet group for the SecureCart database tier"
  subnet_ids  = [var.private_subnet_a_id, var.private_subnet_b_id]

  tags = {
    Name        = "${var.project}-rds-subnet-group"
    Environment = "development"
  }
}


resource "aws_db_instance" "rds_instance_TS" {
  identifier        = "${var.project}-db-instance"
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "mysql"
  engine_version    = "8.4"
  instance_class    = "db.t3.micro"

  db_name  = "SecureCartDB"
  
  # 1. Provide the username string natively
  username = "db_admin" 

  # 2. Force AWS to natively generate the secret container and the password
  manage_master_user_password   = true
  master_user_secret_kms_key_id = "alias/aws/secretsmanager"

  # Networking & Security
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name        = "RDS instance for our SecureCart application"
    Environment = "development"
  }
}
