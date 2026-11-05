provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_lb" "securecart_alb" {
  name = "securecart-alb"
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "securecart-alb-access-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows easy cleanup if needed
}

resource "aws_s3_bucket_policy" "allow_alb_logging" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

resource "aws_sns_topic" "alb_alerts" {
  name = "securecart-alb-alerts-topic"
}

resource "aws_cloudwatch_metric_alarm" "alb_504_timeout" {
  alarm_name          = "securecart-alb-504-timeout-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_504_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # Check every 1 minute
  statistic           = "Sum"
  threshold           = 1 # Trigger if 1 or more 504 errors occur
  alarm_description   = "This alarm triggers when the SecureCart ALB experiences HTTP 504 Gateway Timeouts."
  alarm_actions       = [aws_sns_topic.alb_alerts.arn]

  dimensions = {
    LoadBalancer = data.aws_lb.securecart_alb.arn_suffix
  }
}
