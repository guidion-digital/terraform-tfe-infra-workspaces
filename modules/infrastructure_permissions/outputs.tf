output "iam_role" {
  description = "Name of the IAM role that gets created when use_oidc is true"
  value       = var.use_oidc ? one(aws_iam_role.workspace[*].name) : null
}

output "iam_user" {
  description = "Name of the IAM user that gets created when use_oidc is false"
  value       = var.use_oidc ? null : one(aws_iam_user.this[*].name)
}
