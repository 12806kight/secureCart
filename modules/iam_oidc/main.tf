# 1. Dynamically retrieve the active AWS Account ID to eliminate hardcoding
data "aws_caller_identity" "current" {}

# 2. Hardened IAM Role matched tightly to your direct main pushes
resource "aws_iam_role" "github_actions_tf" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
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
    Name        = "${var.project}-github-actions-role"
    Environment = "development"
  }
}

# 3. Create a custom Least-Privilege Policy (Replacing AdministratorAccess)
resource "aws_iam_policy" "tf_least_privilege" {
  name        = "securecart-terraform-execution-policy"
  description = "Scoped permissions for SecureCart Terraform pipeline execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "elasticloadbalancing:*",
          "s3:*",
          "wafv2:*",
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*" # Restrict further to specific ARNs for true zero-trust isolation
      }
    ]
  })
}

# 4. Attach the custom scoped policy instead of full administrative privileges
resource "aws_iam_role_policy_attachment" "tf_scoped_attach" {
  role       = aws_iam_role.github_actions_tf.name
  policy_arn = aws_iam_policy.tf_least_privilege.arn
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_tf.arn
  description = "Copy this ARN into your GitHub Actions workflow configuration"
}
