# 1. Corrected OIDC Provider for GitHub (URL must be token.actions.githubusercontent.com)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. Hardened IAM Role matched tightly to your direct main pushes
resource "aws_iam_role" "github_actions_tf" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            
            # Fixed to use your precise decoded token value for direct pushes to main
            "token.actions.githubusercontent.com:sub" = "repo:12806kight@51365792/secureCart@1446240309:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# 3. Attach administrative permissions
resource "aws_iam_role_policy_attachment" "tf_admin" {
  role       = aws_iam_role.github_actions_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_tf.arn
  description = "Copy this ARN into your GitHub Actions workflow configuration"
}
