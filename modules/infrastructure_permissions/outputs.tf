output "iam_role" {
  description = "Name of the IAM role that gets created"
  value       = aws_iam_role.workspace.name
}

output "iam_user" {
  description = "Deprecated: use iam_role instead"
  value       = aws_iam_role.workspace.name
}
