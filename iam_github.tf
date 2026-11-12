data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =========================================================================
# 1. EC2 Instance Role & Profile (Least Privilege)
# =========================================================================

resource "aws_iam_role" "ec2_ecr_role" {
  name = "securecart-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Keep ECR ReadOnly so EC2 can pull Docker images
resource "aws_iam_role_policy_attachment" "ec2_ecr_readonly" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Custom inline policy replacing SecretsManagerReadWrite & AmazonSSMReadOnlyAccess
resource "aws_iam_role_policy" "ec2_least_privilege_secrets" {
  name = "SecureCart-EC2-SecretsAndParams-Policy"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSpecificSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/securecart/*"
      },
      {
        Sid    = "ReadSpecificRDSSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:securecart/rds*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "securecart-ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# =========================================================================
# 2. GitHub OIDC Provider & Role (Scoped Deployment Policy)
# =========================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

resource "aws_iam_role" "github_actions_role" {
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
            "token.actions.githubusercontent.com:sub" = "repo:12806kight@51365792/secureCart@1446240309:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Custom inline policy replacing AdministratorAccesses
resource "aws_iam_role_policy" "github_actions_scoped_deploy" {
  name = "SecureCart-GitHubActions-ScopedDeploy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CoreInfrastructureAndNetworking"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "rds:*",
          "route53:*",
          "acm:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "StorageContainersAndEdge"
        Effect = "Allow"
        Action = [
          "s3:*",
          "ecr:*",
          "cloudfront:*",
          "wafv2:*",
          "dynamodb:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConfigSecretsAndMonitoring"
        Effect = "Allow"
        Action = [
          "ssm:*",
          "secretsmanager:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ScopedIAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetInstanceProfile",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/securecart*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/SecureCart*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ec2*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/securecart*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/SecureCart*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/ec2*"
        ]
      },
      {
        Sid    = "ManageGitHubOIDCProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:DeleteOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
    ]
  })
}
