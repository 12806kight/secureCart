data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com" # Added token.actions.
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com" # Added token.actions.
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}


###############################################################################
# 3. OIDC TRUST POLICY DOCUMENT
# Maps the exact literal Subject (sub) claim from your decoded token payload
# to guarantee AWS opens the front door for your pipeline runs.
###############################################################################
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:12806kight@51365792/secureCart@1446240309:ref:refs/heads/main"]
    }
  }
}

###############################################################################
# 4. THE IAM ROLE DEFINITIONs
# Instantiates the core pipeline role. It does NOT contain nested inline
# policy blocks to prevent configuration drifts or duplicate resource issues.
###############################################################################
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Environment = "development"
    Application = "SecureCart"
  }
}
