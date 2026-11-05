
# If the provider doesn't exist in your account yet, uncomment this to create it:
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://githubusercontent.com"
  client_id_list  = ["://amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. Create the IAM Role for GitHub Actions
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
            "://githubusercontent.com:aud" = "://amazonaws.com"
          }
          StringLike = {
            # Tighten security by replacing '*' with your specific GitHub Org/Repo name
            "://githubusercontent.com:sub" = "repo:https://github.com/12806kight/secureCart:*"
          }
        }
      }
    ]
  })
}

# 3. Attach administrative permissions so it can manage your infrastructure
resource "aws_iam_role_policy_attachment" "tf_admin" {
  role       = aws_iam_role.github_actions_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_tf.arn
  description = "Copy this ARN into your GitHub Actions workflow configuration"
}
