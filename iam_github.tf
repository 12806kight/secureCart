# 1. Looks up the OIDC Provider using the standard URL format
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}


# 2. Define the OIDC Trust Policy Document
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "://githubusercontent.com:aud"
      values   = ["://amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "://githubusercontent.com:sub"
      values   = ["repo:12806kight/secureCart:ref:refs/heads/main"]
    }
  }
}

# 3. Create or Manage the IAM Role
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Environment = "development"
    Application = "SecureCart"
  }
}

# 4. Define the Customer Inline Policy
resource "aws_iam_role_policy" "github_actions_inline_policy" {
  name = "securecart-terraform-execution-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PipelineIAMPermissions"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecureCartCoreServices"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}
