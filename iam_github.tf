# 1. Dynamically retrieve your AWS Account ID
data "aws_caller_identity" "current" {}

# 2. Create the IAM Role with the exact-match string required for your private repository
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
            # Matches the exact audience requested by your workflow step
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # Explicitly matches your private repository parameter string to satisfy security filters
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

# 3. Attach Administrative permissions so the pipeline can manage and deploy all modules
resource "aws_iam_role_policy_attachment" "pipeline_admin_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
