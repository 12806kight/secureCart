# 1. Application Load Balancer Security Group (Public facing)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Controls public web traffic to the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allows secure HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allows standard HTTP traffic for automated redirects"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allows ALB to route traffic forward to application nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    description = "Allows all outbound traffic for package installations and ECR pulls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-app-sg"
    Environment = "development"
  }
}

# 3. Database Tier Security Group (Isolated layer)
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

  egress {
    description = "Allows standard outbound database service calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-rds-sg"
    Environment = "development"
  }
}
