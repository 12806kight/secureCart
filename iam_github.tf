# 1. Looks up the OIDC Provider using the standard URL format
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. Define the FIXED OIDC Trust Policy Document
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # FIX: Corrected audience key name and standard token value
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # RECOMMENDED: Switched to StringLike with wildcards to avoid strict ID matches breaking down the line
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:12806kight*/secureCart*:*"]
    }
  }
}

# 3. Manage the IAM Role (Without nested inline fields)
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Environment = "development"
    Application = "SecureCart"
  }
}

# 4. FIXED: Create a Standalone Customer Managed Policy (Best Practice)
resource "aws_iam_policy" "securecart_managed_policy" {
  name        = "securecart-terraform-execution-policy"
  description = "Customer Managed policy for SecureCart IaC pipeline automation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecureCartInfrastructureAutomation"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "elasticloadbalancing:*",
          "s3:*",
          "wafv2:*",
          "autoscaling:*",
          "route53:*",
          "acm:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "PipelineIAMManagementPermissions"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:GetPolicyVersion",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecureCartServiceBoundPassRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "rds.amazonaws.com",
              "application-autoscaling.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# 5. Connect Your New Managed Policy directly to Your Role
resource "aws_iam_role_policy_attachment" "pipeline_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.securecart_managed_policy.arn
}

# 6. Import Block to sync existing Role State smoothly
import {
  to = aws_iam_role.github_actions_role
  id = "github-actions-terraform-role"
}
