module "vpc" {
  source = "./modules/vpc"
}

module "securityGroup" {
  source = "./modules/securityGroup"

  # Connects the output of the VPC module to the input of the SG module
  vpc_id  = module.vpc.vpc_id
  project = var.project

  vpc_cidr_block = module.vpc.vpc_cidr
}

module "rds" {
  source = "./modules/rds"

  project              = var.project
  db_security_group_id = module.securityGroup.db_sg_id
  multi_az             = var.multi_az

  # References the outputs exported by the VPC module block above
  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id
}

module "ec2" {
  source = "./modules/ec2"

  project = var.project

  # Passes the VPC ID down as required by your ec2/variables.tf file
  vpc_id = module.vpc.vpc_id

  # Point to app_sg_id
  app_security_group_id = module.securityGroup.app_sg_id

  # Matches the exact output block name in modules/loadBalancer/outputs.tf
  alb_target_group_arn = module.loadBalancer.target_group_arn

  # Collects both private subnets into a single configuration list for the ASG
  private_subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]

  # CORRECT REFERENCE: Pulls directly from the resource defined inside your root iam_github.tf
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
  ecr_repository_url        = module.ecr.repository_url
}

module "loadBalancer" {
  source = "./modules/loadBalancer"

  project                 = var.project
  vpc_id                  = module.vpc.vpc_id
  alb_security_group_id   = module.securityGroup.alb_sg_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  certificate_arn         = aws_acm_certificate.securecart_cert.arn # Matches module.cloudfront
  cloudfront_secret_token = var.cloudfront_secret_token
  alb_logs_bucket_id      = aws_s3_bucket.alb_logs.id

  depends_on = [aws_s3_bucket_policy.allow_alb_logging]
}

module "waf" {
  source     = "./modules/waf"
  project    = var.project
  alb_arn    = module.loadBalancer.alb_arn
  enable_waf = false
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "securecart-tf-state-prod"
}

module "ecr" {
  source      = "./modules/ecr"
  project     = var.project
  environment = "development"
}

module "cloudfront" {
  source                  = "./modules/cloudfront"
  project                 = var.project
  alb_dns_name            = module.loadBalancer.alb_dns_name
  acm_certificate_arn     = aws_acm_certificate.securecart_cert.arn # Must be in us-east-1
  cloudfront_secret_token = var.cloudfront_secret_token
}

