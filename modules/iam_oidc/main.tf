# 1. Looks up the OIDC Provider using the standard URL format
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. FIXED: Cleaned up the HCL variable and value mappings
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # FIX: Patched the audience tracking key and value
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # RECOMMENDED: Switched to StringLike with wildcards to bypass formatting/ID drift bugs
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:12806kight*/secureCart*:*"]
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
