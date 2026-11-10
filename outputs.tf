output "securecart_url" {
  description = "The public URL to access your secureCart application"
  value       = "http://${module.loadBalancer.alb_dns_name}"
}

output "cloudfront_domain_name" {
  value       = module.cloudfront.cloudfront_domain_name
  description = "The auto-generated public domain name of your CloudFront Edge distribution"
}

output "cloudfront_hosted_zone_id" {
  value       = module.cloudfront.cloudfront_hosted_zone_id
  description = "The CloudFront Route 53 Zone ID"
}
