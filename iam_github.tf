# 1. Fetch your existing OIDC provider info (or define it if needed)
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::298490729231:oidc-provider/://githubusercontent.com"
}

# 2. Define the Trust Policy (AssumeRole with Web Identity)
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
      values   = ["repo:12806kight@51365792/secureCart@1446240309:ref:refs/heads/main"]
    }
  }
}

# 3. Create or manage the IAM Role
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Environment = "development"
    Application = "SecureCart"
  }
}

# 4. Attach the Inline Permissions Policy to the Role
resource "aws_iam_role_policy" "github_actions_permissions" {
  name   = "github-actions-terraform-permissions"
  role   = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "TerraformRoute53Permissions"
        Effect   = "Allow"
        Action   = [
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Sid      = "TerraformACMPermissions"
        Effect   = "Allow"
        Action   = [
          "acm:DescribeCertificate",
          "acm:ListCertificates"
        ]
        Resource = "arn:aws:acm:us-east-1:298490729231:certificate/1c132f23-2f91-469d-a924-929ddc71ee8d"
      },
      {
        Sid      = "TerraformRDSPermissions"
        Effect   = "Allow"
        Action   = [
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance"
        ]
        Resource = "arn:aws:rds:us-east-1:298490729231:db:db-TD6WJ4GAMW3U5NRHCJ3LYK32GI" # Your RDS Instance ARN
      }
    ]
  })
}
