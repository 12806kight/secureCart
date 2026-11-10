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

  # ADD THIS LINE BACK: Passes the VPC ID down as required by your ec2/variables.tf file
  vpc_id = module.vpc.vpc_id

  # FIXED LINE 36: Point to app_sg_id
  app_security_group_id = module.securityGroup.app_sg_id

  # FIXED LINE 40: Matches the exact output block name in modules/loadBalancer/outputs.tf
  alb_target_group_arn = module.loadBalancer.target_group_arn

  # Collects both private subnets into a single configuration list for the ASG
  private_subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]

  ec2_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
  ecr_repository_url        = module.ecr.repository_url
}


module "loadBalancer" {
  source = "./modules/loadBalancer"

  project = var.project
  vpc_id  = module.vpc.vpc_id

  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn
  public_subnet_ids = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]

  alb_security_group_id = module.securityGroup.alb_sg_id
}

module "waf" {
  source = "./modules/waf"

  project = var.project

  # Passes the load balancer ARN output straight into the WAF module block
  alb_arn = module.loadBalancer.alb_arn
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "securecart-tf-state-prod"
}

module "iam_oidc" {
  source  = "./modules/iam_oidc"
  project = var.project
}

module "ecr" {
  source      = "./modules/ecr"
  project     = var.project
  environment = "development"
}
