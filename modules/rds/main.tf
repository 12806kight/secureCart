resource "aws_db_subnet_group" "this" {
  name        = "${var.project}-rds-subnet-group"
  description = "Isolated private subnet group for the SecureCart database tier"

  # References your architecture's private subnet IDs
  subnet_ids = [var.private_subnet_a_id, var.private_subnet_b_id]

  tags = {
    Name        = "${var.project}-rds-subnet-group"
    Environment = "development"
  }
}

resource "aws_db_instance" "rds_instance_TS" {
  identifier        = "${var.project}-db-instance"
  allocated_storage = 20    # Stays strictly inside the AWS Free Tier (Max 30GB allocated)
  storage_type      = "gp3" # General Purpose SSD storage
  engine            = "mysql"
  engine_version    = "8.0"

  # MODIFIED: db.t3.micro is covered under the 12-Month Free Tier (750 hours/month)
  instance_class    = "db.t3.micro" 

  # Database Credentials (Injected from variables)
  db_name  = "SecureCartDB"
  username = var.db_username
  password = var.db_password

  # Networking & Virtual Firewalls
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]

  publicly_accessible = false        

  # MODIFIED: Multi-AZ is disabled to avoid immediate non-Free Tier billing charges
  multi_az            = false 

  # Safety Guardrails
  skip_final_snapshot = true # Fast teardowns for development

  tags = {
    Name        = "RDS instance for our SecureCart application"
    Environment = "development"
  }
}
