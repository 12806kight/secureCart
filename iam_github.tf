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
              "://amazonaws.com",
              "://amazonaws.com",
              "://amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}
