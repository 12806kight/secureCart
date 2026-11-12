data "aws_caller_identity" "current" {}

# 1. Hardened S3 Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "securecart-alb-access-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# 2. Separate Resource to Block All Public Access
resource "aws_s3_bucket_public_access_block" "alb_logs_privacy" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Enforce Free-Tier Compliant SSE-S3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_encryption" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Lifecycle Clean-up Rule
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "cleanup-old-alb-logs"
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}

# 5. Hardened Bucket Policy (ALB Access + HTTPS Enforced)
resource "aws_s3_bucket_policy" "allow_alb_logging" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBSigning"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "EnforceSecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 6. Performance Alert Topic
resource "aws_sns_topic" "alb_alerts" {
  name = "securecart-alb-alerts-topic"
}

# 7. CloudWatch Timeout Metric Alarm
resource "aws_cloudwatch_metric_alarm" "alb_504_timeout" {
  alarm_name          = "securecart-alb-504-timeout-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_504_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This alarm triggers when the SecureCart ALB experiences HTTP 504 Gateway Timeouts."
  alarm_actions       = [aws_sns_topic.alb_alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.securecart_alb.arn_suffix
  }
}
