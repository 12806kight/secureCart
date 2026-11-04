resource "aws_lb" "securecart_alb" {
  name = "${var.project}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [var.alb_security_group_id]
  subnets = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project}-alb"
    Environment = "development"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project}-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/" # Adjust to your app's health check endpoint (e.g., /health)
    port                = "8080"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project}-target-group"
    Environment = "development"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.securecart_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}