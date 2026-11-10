# 1. Dynamically retrieve your AWS Account ID
data "aws_caller_identity" "current" {}

# =========================================================================
# GITHUB ACTIONS OIDC PIPELINE CONFIGURATION
# =========================================================================

# 2. Re-establish the resource block so Terraform builds it cleanly
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# 3. Create the IAM Role with the exact-match string required for your private repository
resource "aws_iam_role" "github_actions_role" {
  name        = "github-actions-terraform-role"
  description = "IAM Role assumed by GitHub Actions to deploy SecureCart infrastructure via OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          # Linked back to your clean resource block
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:12806kight@51365792/secureCart@1446240309:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-terraform-role"
    Project     = "SecureCart"
    Environment = "development"
  }
}

# 4. Attach Administrative permissions so the pipeline can manage and deploy all modules
resource "aws_iam_role_policy_attachment" "pipeline_admin_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# =========================================================================
# EC2 APPLICATION INSTANCE PROFILE CONFIGURATION
# =========================================================================

# 5. Create an IAM Role for your EC2 instances to assume
resource "aws_iam_role" "ec2_ecr_role" {
  name = "${var.project}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 6. Create the physical Instance Profile container that wraps the role for EC2 consumption
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# 7. Attach the AWS-managed policy that allows pulling container images from ECR
resource "aws_iam_role_policy_attachment" "ec2_ecr_readonly" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 8. Attach the core SSM policy to your EC2 instance role for Session Manager access
resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 9. Attach SSM Read Access to your EC2 instance role so it can read parameters
resource "aws_iam_role_policy_attachment" "ec2_ssm_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# 10. Attaches the Secrets Manager policy directly to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_secrets_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
