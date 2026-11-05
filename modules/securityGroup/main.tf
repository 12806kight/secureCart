###############################################################################
# 1. SECURITY GROUP CONTAINERS (Created first to avoid dependency loops)
###############################################################################

resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Controls public traffic to the Application Load Balancer"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-alb-sg", Environment = "development" }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.project}-app-sg"
  description = "Allows traffic exclusively from the ALB"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-app-sg", Environment = "development" }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project}-db-sg"
  description = "Allows traffic to the Database"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-db-sg", Environment = "development" }
}

###############################################################################
# 2. LOAD BALANCER RULES (ALB TIER)
###############################################################################

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_egress_to_app" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id # Breaks circular reference
  security_group_id        = aws_security_group.alb_sg.id
}

###############################################################################
# 3. APPLICATION SERVER RULES (APP TIER)
###############################################################################

resource "aws_security_group_rule" "app_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.app_sg.id
}

# Fixes the app's ability to pull OS updates / node modules / packages over HTTPS
resource "aws_security_group_rule" "app_egress_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Safe behind a private subnet NAT Gateway
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_egress_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_sg.id # Fixed typo reference name
  security_group_id        = aws_security_group.app_sg.id
}

###############################################################################
# 4. DATABASE RULES (DATABASE TIER)
###############################################################################

resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id        = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "db_egress_internal_only" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block] # Confined tightly inside your internal VPC network
  security_group_id = aws_security_group.db_sg.id
}
