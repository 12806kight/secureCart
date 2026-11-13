# Lookup AWS's official CloudFront IP ranges so direct ALB requests are dropped at the firewall
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# 1. Application Load Balancer Security Group (Restricted to CloudFront Edge Only)
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project}-alb-sg-"
  description = "Controls traffic to the ALB strictly from CloudFront edge nodes"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
  # ... keep your ingress and egress rules ...


  ingress {
    description     = "Allows HTTPS traffic exclusively from CloudFront"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "Allows ALB to forward traffic exclusively to app servers on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name        = "${var.project}-alb-sg"
    Environment = "development"
  }
}

# 2. Application Server Security Group (Private layer)
resource "aws_security_group" "SCapp_sg" {
  name        = "Secure Cart App SG"
  description = "Security group for secure-cart application servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allows inbound HTTP traffic exclusively from the ALB on port 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allows outbound HTTPS for ECR pulls, SSM, and Secrets Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allows outbound HTTP for Ubuntu apt package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allows outbound MySQL traffic to RDS inside the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name        = "${var.project}-app-sg"
    Environment = "development"
  }
}

# 3. Database Tier Security Group (Isolated layer - Zero outbound access)
resource "aws_security_group" "rds_sg" {
  name        = "Secure Cart RDS SG"
  description = "Isolates the database tier to accept entries only from app instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allows inbound MySQL traffic on port 3306 from the application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.SCapp_sg.id]
  }

  tags = {
    Name        = "${var.project}-rds-sg"
    Environment = "development"
  }
}
