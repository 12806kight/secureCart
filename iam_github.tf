###############################################################################
# 1. STATE IMPORT ALIGNMENT
# Maps the role to the correct address within the module structure to stop
# EntityAlreadyExists and destroy/recreate loops.
###############################################################################
import {
  to = module.iam_oidc.aws_iam_role.github_actions_role
  id = "github-actions-terraform-role"
}

###############################################################################
# 2. STANDALONE CUSTOMER MANAGED POLICY
# Full management permissions over core services, combined with comprehensive
# IAM permissions for self-mutation, and a safe, restricted PassRole block.
###############################################################################
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
          "iam:DeletePolicyVersion",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:DeleteRole"
        ]
        Resource = "*"
      },
      {
        Sid      = "SecureCartServiceBoundPassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
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

###############################################################################
# 3. POLICY TO ROLE ATTACHMENT LINK
# Binds the customer managed policy directly to the role instantiated inside
# your iam_oidc subdirectory module.
###############################################################################
resource "aws_iam_role_policy_attachment" "pipeline_policy_attachment" {
  role       = module.iam_oidc.role_name
  policy_arn = aws_iam_policy.securecart_managed_policy.arn # Fixed name from pipeline_policy
}