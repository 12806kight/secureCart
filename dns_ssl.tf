###############################################################################
# 1. LOOKUP YOUR LIVE HOSTED ZONE
###############################################################################
data "aws_route53_zone" "primary" {
  name         = "securetestkight.com." # Note the trailing dot
  private_zone = false
}

###############################################################################
# 2. REQUEST THE FREE PUBLIC SSL CERTIFICATE
###############################################################################
resource "aws_acm_certificate" "securecart_cert" {
  domain_name       = "securetestkight.com"
  validation_method = "DNS"

  tags = {
    Name        = "${var.project}-ssl-cert"
    Environment = "development"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# 3. AUTOMATICALLY CREATE DNS VALIDATION RECORDS IN ROUTE 53
###############################################################################
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.securecart_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

###############################################################################
# 4. TRIGGER THE CERTIFICATE VALIDATION HANDSHAKE
###############################################################################
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.securecart_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

###############################################################################
# 5. ROUTE TRAFFIC FROM THE DOMAIN STRAIGHT TO YOUR ALB
###############################################################################
resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "securetestkight.com"
  type    = "A"

  alias {
    name                   = module.loadBalancer.alb_dns_name
    zone_id                = module.loadBalancer.alb_zone_id # Adjust this path to match your root module's ALB output path
    evaluate_target_health = true
  }
}
