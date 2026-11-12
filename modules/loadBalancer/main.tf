resource "aws_lb" "securecart_alb" {
  name                       = "${var.project}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.allow_alb_logging]

  tags = {
    Name        = "${var.project}-alb"
    Environment = "development"
  }
}

resource "aws_lb_target_group" "app_tg" {
  # ... other settings ...
  port     = 8080 # MUST match the port specified in your security group!
  protocol = "HTTP"
  vpc_id   = var.vpc_id


  health_check {
    enabled             = true
    path                = "/health" # UPDATED: Pointing to your server.js health check endpoint
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
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# 2. Update the HTTPS listener to block direct traffic by default
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.securecart_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Direct ALB access is forbidden."
      status_code  = "403"
    }
  }
}

# 3. Allow traffic ONLY when CloudFront sends the matching custom header
resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  condition {
    http_header {
      http_header_name = "X-Custom-SecureCart-Token"
      values           = [var.cloudfront_secret_token]
    }
  }
}
