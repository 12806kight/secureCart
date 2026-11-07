# 1. Dynamically retrieve your AWS Account ID
data "aws_caller_identity" "current" {}

# 2. Configure the OIDC Provider for GitHub globally in your AWS account
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Standard thumbprint for GitHub Actions token service
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 3. Create the IAM Role with the trust policy tailored to your workflow configuration
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
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            # Must match the audience requested by aws-actions/configure-aws-credentials
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restricts role assumption specifically to your secureCart repository
            "token.actions.githubusercontent.com:sub" = "repo:12806kight/secureCart:*"
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

# 4. Attach Administrative permissions so the pipeline can deploy VPC, EC2, ALB, and RDS module
resource "aws_iam_role_policy_attachment" "pipeline_admin_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
