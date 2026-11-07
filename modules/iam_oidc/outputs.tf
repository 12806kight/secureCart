output "role_name" {
  description = "The name of the IAM role created for GitHub Actions"
  value       = aws_iam_role.github_actions_role.name
}
