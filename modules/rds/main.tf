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
  identifier            = "${var.project}-db-instance"
  allocated_storage     = 20  # Safe maximum to stay strictly inside the AWS Free Tier (Max 30GB)
  max_allocated_storage = 100 # Enables storage autoscaling without manual intervention
  storage_type          = "gp3"
  engine                = "mysql"        # Ensure this matches your port 3306 rules
  engine_version        = "8.0"          # Declaring an explicit minor version avoids AWS API deployment errors
  instance_class        = "db.t4g.micro" # Cost-efficient instance type

  # Database Credentials (Injected from variables)
  db_name  = "SecureCartDB"
  username = var.db_username
  password = var.db_password

  # Networking & Virtual Firewalls
  db_subnet_group_name = aws_db_subnet_group.this.name

  # Hooks directly to the core container defined in your security group file
  vpc_security_group_ids = [var.db_security_group_id]

  publicly_accessible = false        # Enforces internal-only traffic from your app servers
  multi_az            = var.multi_az # Managed easily via boolean toggle

  # Safety Guardrails
  skip_final_snapshot = true # Fast teardowns for development (Set to false for real production)

  tags = {
    Name        = "RDS instance for our SecureCart application"
    Environment = "development"
  }
}
