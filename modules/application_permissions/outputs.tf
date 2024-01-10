output "application_iam_role_arn" {
  value = one(aws_iam_role.application[*].arn)
}

output "iam_user" {
  description = "Name of the IAM user that gets created"
  value       = aws_iam_user.this.name
}
