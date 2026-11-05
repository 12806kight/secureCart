output "securecart_url" {
  description = "The public URL to access your secureCart application"
  value       = "http://${module.loadBalancer.alb_dns_name}"
}
