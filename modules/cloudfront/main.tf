resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront Distribution for ${var.project}"
  price_class     = "PriceClass_100" # Free Tier optimal (US/Europe edge locations)

  # Add this line (or use a variable like var.domain_aliases)
  aliases = ["securetestkight.com"]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.project}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer" # Matches traffic encryption protocol
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-SecureCart-Token"
      value = var.cloudfront_secret_token
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.project}"

    forwarded_values {
      query_string = true
      headers      = ["Host"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0 # Forces dynamic app requests down to EC2
    max_ttl                = 0
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "${var.project}-cloudfront"
    Environment = "development"
  }
}
