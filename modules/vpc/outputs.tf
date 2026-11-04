output "all_subnet_ids" {
  description = "A map of all subnet keys to their corresponding IDs."
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "private_subnet_ids" {
  description = "List of IDs for subnets designated as private."
  value       = [for k, v in aws_subnet.this : v.id if var.subnets[k].type == "private"]
}

output "public_subnet_ids" {
  description = "List of IDs for subnets designated as public."
  value       = [for k, v in aws_subnet.this : v.id if var.subnets[k].type == "public"]
}

output "subnet_cidr_blocks" {
  description = "A map of subnet keys to their CIDR blocks for verification."
  value       = { for k, v in aws_subnet.this : k => v.cidr_block }
}

# /modules/vpc/outputs.tf

output "vpc_id" {
  value       = aws_vpc.securecart-vpc.id
  description = "The ID of the SecureCart VPC"
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "The CIDR block of the created VPC"
}

output "private_subnet_a_id" {
  description = "The ID of the private subnet A"
  value       = aws_subnet.this["private_a"].id
}

output "private_subnet_b_id" {
  description = "The ID of the private subnet B"
  value       = aws_subnet.this["private_b"].id
}

output "public_subnet_a_id" {
  description = "The ID of public subnet A"
  value       = aws_subnet.this["public_a"].id
}

output "public_subnet_b_id" {
  description = "The ID of public subnet B"
  value       = aws_subnet.this["public_b"].id
}
